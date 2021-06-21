// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./utils/SafeMath.sol";
import "./interfaces/IVeeTokenTransferBridge.sol";
import "./interfaces/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./VeeSystemController.sol";
/**
 * @title  Vee's Token Transfer Bridge Contract
 * @notice Implementation of the VeeSystemController.
 * @author Vee.Finance
 */
contract VeeTokenTransferBridge is IVeeTokenTransferBridge, VeeSystemController, Initializable{    
    using SafeMath for uint256;

    address private pNativetoken;

    /**
     * @dev increasing number for generating random.
     */
    uint256 private nonce;

    /**
     * @dev bridge fee
     */
    uint256 private pBridgeFee;

    /**
     * @dev network fee
     */
    uint256 private pNetworkFee;

    /**
     * @dev Application data
     */
    struct Application {
        address applicant;
        address receiver;
        address fromToken;
        string  fromTokenName;
        address toToken;
        string  toTokenName;
        uint256 fromAmount;
        uint256 toAmount;
        uint256 bridgeFee;
        uint256 networkFee;
    }

    /**
     * @dev Transfer data
     */
    struct Transfer {
        address applicant;
        address receiver;
        string  fromTokenName;
        address toToken;
        string  toTokenName;
        uint256 toAmount;
        uint256 pairPrice;
    }
    
    /**
     * @dev Transfer data
     */
    struct BalanceOperationLog {
        address operator;
        address tokenAddress;
        uint256 amount;
        address toAddress;
        BalanceOperateType operateType;
    }

    /**
     * @dev account balance operation logs
     */
    mapping (bytes32 => BalanceOperationLog) private balanceOperationLog;

    /**
     * @dev container for saving applicationId and application infornmation
     */
    mapping (bytes32 => Application) private applications;

    /**
     * @dev container for saving applicationId dand transfer infornmation
     */
    mapping (bytes32 => Transfer) private transfers;

    /**
     * @dev called for plain Ether transfers
     */
    receive() payable external{}

    /**
     * @dev initialize for initializing UNISWAP router and CETH
     */
    function initialize() public initializer {
        _setRoleAdmin(PROXY_ADMIN_ROLE, PROXY_ADMIN_ROLE);
        _setRoleAdmin(EXECUTOR_ROLE,    PROXY_ADMIN_ROLE);

        // deployer + self administration
        _setupRole(PROXY_ADMIN_ROLE, _msgSender());
        _setupRole(PROXY_ADMIN_ROLE, address(this));

        // executor
        _setupRole(EXECUTOR_ROLE, _msgSender());
        _notEntered = true;

        pBridgeFee  = 1e15;
        pNetworkFee = 5e15;

        pNativetoken = address(1);
    }

    /*** External admin Functions ***/
    
    /**
     * @dev charge native token
     */
    function chargeNative() external payable 
                            returns (bytes32 operateId){
        require(msg.value > 0, "chargeNative: msg.value should be greater than zero.");

        operateId = keccak256(abi.encode(msg.sender, address(this), msg.value, getRandom()));    
        
        BalanceOperationLog memory operation = BalanceOperationLog(msg.sender, pNativetoken, msg.value, address(this),BalanceOperateType.Charge);
        balanceOperationLog[operateId] = operation;
        
        emit OnOperateBalance(operateId, msg.sender, pNativetoken, msg.value,address(this), BalanceOperateType.Charge);
    }

    /**
     * @dev charge ERC20
     * @param token  the address of Erc20
     * @param amount the amount of charging  
     */
    function chargeErc20(address token, uint256 amount) external 
                         returns (bytes32 operateId){
        require(amount > 0, "chargeErc20: amount should be greater than zero.");

        {
            IERC20 erc20TokenA = IERC20(token);
            uint256 allowance = erc20TokenA.allowance(msg.sender, address(this));
            require(allowance >= amount,"applyTransferERC20ToETH: allowance must be greater than amountA");
            assert(erc20TokenA.transferFrom(msg.sender, address(this), amount));
        }

        operateId = keccak256(abi.encode(msg.sender, address(this), amount, getRandom()));    
        
        BalanceOperationLog memory operation = BalanceOperationLog(msg.sender, pNativetoken, amount, address(this), BalanceOperateType.Charge);
        balanceOperationLog[operateId] = operation;
        
        emit OnOperateBalance(operateId, msg.sender,token,amount,address(this),BalanceOperateType.Charge);
    }

     /**
     * @dev Transfer TO ERC20.
     *
     * @param receiver       The address of receiver
     * @param amount         The transfer amount of from token   
     *
     * @return operateId 
     */
    function extractNative(address receiver, uint256 amount) 
                           onlyAdmin nonReentrant veeLock(uint8(VeeLockState.LOCK_EXECUTEDORDER)) external 
                           returns (bytes32 operateId){     
        
        payable(receiver).transfer(amount);

        operateId = keccak256(abi.encode(msg.sender, address(this), amount, getRandom()));    
        
        BalanceOperationLog memory operation = BalanceOperationLog(msg.sender,pNativetoken,amount,receiver,BalanceOperateType.Extract);
        balanceOperationLog[operateId] = operation;
        
        emit OnOperateBalance(operateId, msg.sender,pNativetoken,amount,receiver,BalanceOperateType.Extract);
    }

     /**
     * @dev Transfer TO ERC20.
     *
     * @param receiver    The address of receiver
     * @param token       The address of target token
     * @param amount      The transfer amount of from token   
     *
     * @return operateId 
     */
    function extractErc20(address receiver, address token, uint256 amount) 
                          onlyAdmin nonReentrant veeLock(uint8(VeeLockState.LOCK_EXECUTEDORDER)) external 
                          returns (bytes32 operateId){     
        assert(IERC20(token).transfer(receiver, amount));

        operateId = keccak256(abi.encode(msg.sender, address(this), amount, getRandom()));    
        
        BalanceOperationLog memory operation = BalanceOperationLog(msg.sender,token,amount,receiver,BalanceOperateType.Extract);
        balanceOperationLog[operateId] = operation;
        
        emit OnOperateBalance(operateId, msg.sender,token,amount,receiver,BalanceOperateType.Extract);
    }

    /**
     * @dev get details of a valid Application .
      *
     * @param operateId  The id of application   
     *
     * @return  operator      The address of operator
     *          tokenAddress  The address of from token
     *          amount        The transfer amount of from token
     *          toAddress     The address of receiver
     *          operateType   The type of operation
     *
     */
    function getOperation(bytes32 operateId) 
                          external view 
                          returns(address operator,
                                  address tokenAddress,
                                  uint256 amount,
                                  address toAddress,
                                  BalanceOperateType operateType){
        BalanceOperationLog memory operation = balanceOperationLog[operateId];
        require(operation.operator != address(0), "getOperation: invalid operateId");

        operator        = operation.operator;
        tokenAddress    = operation.tokenAddress;
        amount          = operation.amount;
        toAddress       = operation.toAddress;
        operateType     = operation.operateType;
    }

    /**
     * @dev set native token by admin
     * @param newNativeToken   The address of new NativeToken   
     */
    function setNativeToken(address newNativeToken) external onlyAdmin {
        require(newNativeToken != address(0), "setNativeToken: address of NativeToken is invalid");
        pNativetoken = newNativeToken;
        emit onChangeNativeToken(pNativetoken);
    }    

    /**
     * @dev set executor role by admin.
     *
     * @param newExecutor  The address of new executor   
     *
     */
    function setExecutor(address newExecutor) external onlyAdmin {
        require(newExecutor != address(0), "setExecutor: address of Executor is invalid");
        grantRole(EXECUTOR_ROLE, newExecutor);
   }    
    
    /**
     * @dev set bridge fee by admin
     * @param bridgeFee_     The new value of Bridge Fee
     */
    function setBridgeFee(uint256 bridgeFee_) external onlyAdmin {
        pBridgeFee = bridgeFee_;
        emit onSetBridgeFee(pBridgeFee,msg.sender);
    }

    /**
     * @dev set gas fee by admin
     * @param networkFee_     The new value of Gas Fee
     */
    function setNetworkFee(uint256 networkFee_) external onlyAdmin {
        pNetworkFee = networkFee_;
        emit onSetNetworkFee(pNetworkFee,msg.sender);
    }

    /**
     * @dev remove an executor role from the list by admin.
     *
     * @param executor  The address of an executor   
     *
     */
    function removeExecutor(address executor) external onlyAdmin {
        require(executor != address(0), "removeExecutor: address of executor is invalid");
        revokeRole(EXECUTOR_ROLE, executor);      
    }  

    /*** External get Functions ***/

    /**
     * @dev get native token address
     */
    function getNativeToken() external view returns (address) {
        return pNativetoken;
    }
    
    /**
     * @dev get bridge fee
     */
    function getBridgeFee() external view returns (uint256) {
        return pBridgeFee;
    }

    /**
     * @dev get gas fee
     */
    function getNetworkFee() external view returns (uint256) {
        return pNetworkFee;
    }
    
    /*** External Functions ***/
     /**
     * @dev Apply transfer from ETH TO ETH.
     *
     * @param receiver      The address of receiver
     * @param fromTokenName The name of source token
     * @param toTokenName   The name of destination token
     *
     * @return applicationId 
     */
    function applyTransferETHToETH(address receiver, string memory fromTokenName, string memory toTokenName) 
                                   override veeLock(uint8(VeeLockState.LOCK_CREATE)) 
                                   external payable 
                                   returns (bytes32 applicationId){
        require(receiver != address(0), "applyTransferETHToETH: invalid receiver address");
        require(msg.value > 0, "applyTransferETHToETH: msg.value should be greater than zero.");

        // get toAmount
        uint256 toAmount = msg.value.sub(pNetworkFee).sub(msg.value.sub(pNetworkFee).mul(pBridgeFee).div(1e18));
        
        applicationId = keccak256(abi.encode(msg.sender, receiver, pNativetoken, pNativetoken,msg.value, getRandom()));    
        
        Application memory application = Application(msg.sender, receiver, pNativetoken, fromTokenName, pNativetoken, toTokenName, msg.value,toAmount, pBridgeFee, pNetworkFee);
        applications[applicationId] = application;
        
        emit OnAppliedTransfer(applicationId, msg.sender, receiver, pNativetoken,fromTokenName, pNativetoken,toTokenName, msg.value,toAmount, pBridgeFee, pNetworkFee);
    }

    /*** External Functions ***/
     /**
     * @dev Apply transfer from ETH TO ERC20.
     *
     * @param receiver      The address of receiver
     * @param fromTokenName The name of source token
     * @param toToken       The address of target token         
     * @param toTokenName   The name of destination token
     *
     * @return applicationId 
     */
    function applyTransferETHToERC20(address receiver, string memory fromTokenName, address toToken, string memory toTokenName) 
                                     override veeLock(uint8(VeeLockState.LOCK_CREATE)) 
                                     external payable 
                                     returns (bytes32 applicationId){
        require(receiver != address(0), "applyTransferETHToERC20: invalid receiver address");
        require(toToken != address(0), "applyTransferETHToERC20: invalid toToken address");
        require(msg.value > 0, "applyTransferETHToERC20: msg.value should be greater than zero.");
        
        // get toAmount
        uint256 toAmount = msg.value.sub(pNetworkFee).sub(msg.value.sub(pNetworkFee).mul(pBridgeFee).div(1e18));

        applicationId = keccak256(abi.encode(msg.sender, receiver, pNativetoken, toToken, msg.value, getRandom()));    
        
        Application memory application = Application(msg.sender, receiver, pNativetoken, fromTokenName, toToken, toTokenName, msg.value,toAmount, pBridgeFee, pNetworkFee);
        applications[applicationId] = application;
        
        emit OnAppliedTransfer(applicationId, msg.sender, receiver, pNativetoken, fromTokenName, toToken,toTokenName, msg.value,toAmount, pBridgeFee, pNetworkFee);

    }

    /*** External Functions ***/
     /**
     * @dev Apply transfer from ERC20 TO ETH.
     *
     * @param receiver      The address of receiver
     * @param fromToken     The address of from token
     * @param fromTokenName The name of source token    
     * @param toTokenName   The name of target token
     * @param amount        The transfer amount of from token
     *
     * @return applicationId 
     */
    function applyTransferERC20ToETH(address receiver, address fromToken, string memory fromTokenName, string memory toTokenName, uint256 amount) 
                                     override veeLock(uint8(VeeLockState.LOCK_CREATE)) 
                                     external payable 
                                     returns (bytes32 applicationId){
        require(receiver != address(0), "applyTransferERC20ToETH: invalid receiver address");   
        require(fromToken != address(0), "applyTransferERC20ToETH: invalid fromToken address");
        require(amount > 0, "applyTransferERC20ToETH: amount should be greater than zero.");
        require(msg.value >= pNetworkFee, "applyTransferETHToERC20: msg.value should be greater than networkFee.");
        
        // get toAmount
        uint256 toAmount = amount.sub(amount.mul(pBridgeFee).div(1e18));
        
        {
            IERC20 erc20TokenA = IERC20(fromToken);
            uint256 allowance = erc20TokenA.allowance(msg.sender, address(this));
            require(allowance >= amount,"applyTransferERC20ToETH: allowance must be greater than amountA");
            assert(erc20TokenA.transferFrom(msg.sender, address(this), amount));
        }
        
        applicationId = keccak256(abi.encode(msg.sender, receiver, fromToken, pNativetoken,amount, getRandom()));    
        
        Application memory application = Application(msg.sender, receiver, fromToken, fromTokenName, pNativetoken, toTokenName, amount,toAmount, pBridgeFee, pNetworkFee);
        applications[applicationId] = application;

        emit OnAppliedTransfer(applicationId, msg.sender, receiver, fromToken, fromTokenName, pNativetoken,toTokenName, amount,toAmount, pBridgeFee, pNetworkFee);
    }

    /*** External Functions ***/
     /**
     * @dev Apply transfer from ERC20 TO ERC20.
     *
     * @param receiver      The address of receiver
     * @param fromToken     The address of from token
     * @param fromTokenName The name of source token
     * @param toToken       The address of target token         
     * @param toTokenName   The name of target token
     * @param amount        The transfer amount of from token
     *
     * @return applicationId 
     */
    function applyTransferERC20ToERC20(address receiver, address fromToken, string memory fromTokenName, address toToken, string memory toTokenName, uint256 amount) 
                                       override veeLock(uint8(VeeLockState.LOCK_CREATE)) 
                                       external payable 
                                       returns (bytes32 applicationId){
        require(receiver != address(0), "applyTransferERC20ToERC20: invalid receiver address");   
        require(fromToken != address(0), "applyTransferERC20ToERC20: invalid fromToken address");
        require(toToken != address(0), "applyTransferERC20ToERC20: invalid toToken address");
        require(amount > 0, "applyTransferERC20ToERC20: amount should be greater than zero.");
        require(msg.value >= pNetworkFee, "applyTransferETHToERC20: msg.value should be greater than networkFee.");
        
        // get toAmount
        uint256 toAmount = amount.sub(amount.mul(pBridgeFee).div(1e18));
        
        {
            IERC20 erc20TokenA = IERC20(fromToken);
            uint256 allowance = erc20TokenA.allowance(msg.sender, address(this));
            require(allowance >= amount,"applyTransferERC20ToERC20: allowance must bigger than amountA");
            assert(erc20TokenA.transferFrom(msg.sender, address(this), amount));
        }
        
        applicationId = keccak256(abi.encode(msg.sender, receiver, fromToken, toToken,amount, getRandom()));    
        
        Application memory application = Application(msg.sender, receiver, fromToken, fromTokenName, toToken, toTokenName, amount,toAmount, pBridgeFee, pNetworkFee);
        applications[applicationId] = application;
           
        emit OnAppliedTransfer(applicationId, msg.sender, receiver, fromToken, fromTokenName, toToken,toTokenName, amount,toAmount, pBridgeFee, pNetworkFee);
    }

    /**
     * @dev get details of a valid Application .
     * @param applicationId  The id of application   
     *
     * @return  applicant  The address of applicant
     *          receiver   The address of receiver
     *          fromToken  The address of from token
     *          toToken    The address of target token
     *          amount     The transfer amount of from token
     *          pairPrice  The pair price
     *          bridgeFee  The bridge fee
     *          networkFee The gas fee for transfer 
     *
     */
    function getApplicationDetail(bytes32 applicationId) external view 
                          returns(address applicant, address receiver, address fromToken,string memory fromTokenName, address toToken, string memory toTokenName, uint256 fromAmount, uint256 toAmount,uint256 bridgeFee, uint256 networkFee){
        Application memory application = applications[applicationId];
        require(application.applicant != address(0), "getApplicationDetail: invalid applicationId");
        applicant     = application.applicant;
        receiver      = application.receiver;
        fromToken     = application.fromToken;
        fromTokenName = application.fromTokenName;
        toToken       = application.toToken;
        toTokenName   = application.toTokenName;
        fromAmount    = application.fromAmount;
        toAmount      = application.toAmount;     
        bridgeFee     = application.bridgeFee;
        networkFee    = application.networkFee;  
    }
    
    /*** External Functions ***/
     /**
     * @dev Transfer TO ERC20.
     *
     * @param applicationId  The id of application  
     * @param applicant      The address of applicant
     * @param receiver       The address of receiver
     * @param fromTokenName  The name of source token
     * @param toToken        The address of target token         
     * @param toTokenName    The name of target token
     * @param amount         The transfer amount of from token 
     * @param pairPrice      The pair price    
     *
     * @return true 
     */
    function executeTransferToERC20(bytes32 applicationId, address applicant, address receiver, string memory fromTokenName, address toToken, string memory toTokenName, uint256 amount, uint256 pairPrice) 
                                    override onlyExecutor nonReentrant veeLock(uint8(VeeLockState.LOCK_EXECUTEDORDER)) external 
                                    returns (bool){  
        Transfer memory transfed = transfers[applicationId];
        require(transfed.applicant == address(0), "executeTransferToERC20: application has been executed");    
        assert(IERC20(toToken).transfer(receiver, amount));

        Transfer memory transfer = Transfer(applicant, receiver, fromTokenName, toToken, toTokenName, amount, pairPrice);
        transfers[applicationId] = transfer;

        emit OnExecutedTransfer(applicationId, applicant, receiver, fromTokenName, toToken, toTokenName, amount, pairPrice);
        return true;
    }

    /*** External Functions ***/
     /**
     * @dev Transfer TO ETH.
     *
     * @param applicationId  The id of application  
     * @param applicant      The address of applicant
     * @param receiver       The address of receiver
     * @param fromTokenName  The name of source token    
     * @param toTokenName    The name of target token
     * @param amount         The transfer amount of from token 
     * @param pairPrice      The pair price    
     *
     * @return true 
     */
    function executeTransferToETH(bytes32 applicationId, address applicant, address receiver, string memory fromTokenName, string memory toTokenName, uint256 amount, uint256 pairPrice) 
                                  override onlyExecutor nonReentrant veeLock(uint8(VeeLockState.LOCK_EXECUTEDORDER)) external 
                                  returns (bool){  
        Transfer memory transfed = transfers[applicationId];
        require(transfed.applicant == address(0), "executeTransferToETH: application has been executed");       

        payable(receiver).transfer(amount);

        Transfer memory transfer = Transfer(applicant, receiver, fromTokenName, pNativetoken, toTokenName, amount, pairPrice);
        transfers[applicationId] = transfer;

        emit OnExecutedTransfer(applicationId, applicant, receiver, fromTokenName, pNativetoken, toTokenName, amount, pairPrice);
        return true;
    }
    /**
     * @dev get details of a valid Application .
      *
     * @param applicationId  The id of application   
     *
     * @return  applicant  The address of applicant
     *          receiver   The address of receiver
     *          fromToken  The address of from token
     *          toToken    The address of target token
     *          amount     The transfer amount of from token
     *          pairPrice  The pair price
     *
     */
    function getTransferDetail(bytes32 applicationId) 
                               external view 
                               returns(address applicant, address receiver, string memory fromTokenName, address toToken, string memory toTokenName, uint256 toAmount, uint256 pairPrice){
        Transfer memory transfer = transfers[applicationId];
        require(transfer.applicant != address(0), "getTransferDetail: invalid applicationId");
        applicant     = transfer.applicant;
        receiver      = transfer.receiver;
        fromTokenName = transfer.fromTokenName;
        toToken       = transfer.toToken;
        toTokenName   = transfer.toTokenName;
        toAmount      = transfer.toAmount;  
        pairPrice     = transfer.pairPrice;
    }

    /*** Private Functions ***/
    /**
     * @dev generate random number.     
     *
     */
   function getRandom() private returns (uint256) {
       nonce++;
       uint256 randomnumber = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, nonce))) ;
       randomnumber = randomnumber + 1;                
       return randomnumber;
    } 
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the IVeeProxyController
 */
interface IVeeTokenTransferBridge {  
    
    /**
     * @dev The type of balance operations
     */
    enum BalanceOperateType { Charge, Extract }

    /**
     * @dev Emitted when `NativeToken` is changed.
     *
     */
    event onChangeNativeToken(address newNativeToken);

    /**
     * @dev Emitted when `BridgeFee` is changed.
     *
     */
    event onSetBridgeFee(uint256 bridgeFee_, address indexed sender);

    /**
     * @dev Emitted when `Network Fee` is changed.
     *
     */
    event onSetNetworkFee(uint256 networkFee_, address indexed sender);

    /**
     * @dev Emitted when Balance is changed.
     *
     */
    event OnOperateBalance(bytes32 indexed operateId, address indexed operator,address token, uint256 amount,address indexed toAddress,BalanceOperateType operateType);

    /**
     * @notice Event emitted when the Apply are created.
     */
	event OnAppliedTransfer(bytes32 indexed applicationId, address indexed applicant, address receiver, address indexed fromToken, string fromTokenName, address toToken, string toTokenName, uint256 fromAmount, uint256 toAmount, uint256 bridgeFee, uint256 networkFee);

    /**
     * @notice Event emitted when the Transfer are Executed.
     */
	event OnExecutedTransfer(bytes32 indexed applicationId, address indexed applicant, address receiver, string fromTokenName, address toToken,string toTokenName, uint256 amount, uint256 pairPrice);    

    /*** External functions ***/
    /**
     * @notice Applying transfer by user
     */
    function applyTransferETHToETH(address receiver, string memory fromTokenName, string memory toTokenName) external payable returns (bytes32);
    function applyTransferETHToERC20(address receiver, string memory fromTokenName, address toToken, string memory toTokenName) external payable returns (bytes32);
    function applyTransferERC20ToETH(address receiver, address fromToken, string memory fromTokenName, string memory toTokenName, uint256 amount) external payable returns (bytes32);
    function applyTransferERC20ToERC20(address receiver, address fromToken, string memory fromTokenName, address toToken, string memory toTokenName, uint256 amount) external payable returns (bytes32);
    
    // /**
    //  * @notice Execute transfer
    //  */
    function executeTransferToERC20(bytes32 applicationId, address applicant, address receiver, string memory fromTokenName, address toToken, string memory toTokenName, uint256 amount, uint256 pairPrice) external returns (bool);
    function executeTransferToETH(bytes32 applicationId, address applicant, address receiver, string memory fromTokenName, string memory toTokenName,uint256 amount, uint256 pairPrice) external returns (bool);
   
 }

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./utils/AccessControl.sol";


/**
 * @title  Vee system controller
 * @notice Implementation of contractor management .
 * @author Vee.Finance
 */

contract VeeSystemController is AccessControl {
    bytes32 public constant PROXY_ADMIN_ROLE = keccak256("PROXY_ADMIN_ROLE");
    bytes32 public constant EXECUTOR_ROLE    =  keccak256("EXECUTOR_ROLE");

    address internal constant VETH = address(1);

    uint256 internal constant baseTokenAmount = 1e8;

    address internal baseToken;

    enum VeeLockState { LOCK_CREATE, LOCK_EXECUTEDORDER, LOCK_CANCELORDER}

    
    /**
     * @dev Guard variable for re-entrancy checks
     */
    bool internal _notEntered;

    /**
     * @dev Lock All external functions
     * 0 unlock 1 lock
     */
    uint8 private _veeUnLockAll; 

    /**
     * @dev Lock createOrder
     * 0 unlock 1 lock
     */
    uint8 private _veeUnLockCreate; 

    /**
     * @dev Lock executeOrder
     * 0 unlock 1 lock
     */
    uint8 private _veeUnLockExecute; 

     /**
     * @dev Lock cancelOrder
     * 0 unlock 1 lock
     */
    uint8 private _veeUnLockCancel; 


    /**
     * @dev Lock the System
     * 0 unlock 1 lock
     */
    uint8 private _sysLockState;


    // address private _implementationAddress;

    /**
     * @dev Modifier throws if called methods have been locked by administrator.
     */
    modifier veeLock(uint8 lockType) {
        require(_sysLockState == 0,"veeLock: Lock System");
        require(_veeUnLockAll == 0,"veeLock: Lock All");

        if(lockType == uint8(VeeLockState.LOCK_CREATE)){
            require(_veeUnLockCreate == 0,"veeLock: Lock Create");
        }else if(lockType == uint8(VeeLockState.LOCK_EXECUTEDORDER)){
            require(_veeUnLockExecute == 0,"veeLock: Lock Execute");
        }else if(lockType == uint8(VeeLockState.LOCK_CANCELORDER)){
            require(_veeUnLockCancel == 0,"veeLock: Lock Cancel");
        }
        _;        
    }

    /**
     * @dev Modifier throws if called by any account other than the administrator.
     */
    modifier onlyAdmin() {
        require(hasRole(PROXY_ADMIN_ROLE, _msgSender()), "VeeSystemController: Admin permission required");
        _;
    }
    
    /**
     * @dev Modifier throws if called by any account other than the executor.
     */
    modifier onlyExecutor() {
        require(hasRole(EXECUTOR_ROLE, _msgSender()), "VeeSystemController: Executor permission required");
        _;
    }
 
    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     */
    modifier nonReentrant() {
        require(_notEntered, "nonReentrant: Warning re-entered!");
        _notEntered = false;
        _;
        _notEntered = true; // get a gas-refund post-Istanbul
    }

     /**
     * @dev set state for locking some or all of functions or whole system.
     *
     * @param sysLockState     Lock whole system
     * @param veeUnLockAll     Lock all of functions
     * @param veeUnLockCreate  Lock create order
     * @param veeUnLockExecute Lock execute order
     *
     */
    function setState(uint8 sysLockState, uint8 veeUnLockAll, uint8 veeUnLockCreate, uint8 veeUnLockExecute, uint8 veeUnLockCancel) external onlyAdmin {
        _sysLockState       = sysLockState;
        _veeUnLockAll       = veeUnLockAll;
        _veeUnLockCreate    = veeUnLockCreate;
        _veeUnLockExecute   = veeUnLockExecute;
        _veeUnLockCancel    = veeUnLockCancel;
    }

    function setBaseToken(address _baseToken) external onlyAdmin {
        baseToken = _baseToken;
    }
    
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Context.sol";
import "./ERC165.sol";

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    function hasRole(bytes32 role, address account) external view returns (bool);
    function getRoleAdmin(bytes32 role) external view returns (bytes32);
    function grantRole(bytes32 role, address account) external;
    function revokeRole(bytes32 role, address account) external;
    function renounceRole(bytes32 role, address account) external;
}

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping (address => bool) members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override {
        require(hasRole(getRoleAdmin(role), _msgSender()), "AccessControl: sender must be an admin to grant");

        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override {
        require(hasRole(getRoleAdmin(role), _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

{
  "optimizer": {
    "enabled": true,
    "runs": 0
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}