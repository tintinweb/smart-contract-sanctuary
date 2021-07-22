/**
 *Submitted for verification at polygonscan.com on 2021-07-22
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

library Math {
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a / 2) + (b / 2) + (((a % 2) + (b % 2)) / 2);
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    modifier validAddress(address addr) {


    require(addr != address(0), "Address cannot be 0x0");
    require(addr != address(this), "Address cannot be contract address");
    _;
    }
    constructor() public{
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

   
    function transferOwnership(address newOwner) public virtual onlyOwner validAddress(newOwner) {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IERC20 {
    
     function decimals() external view returns (uint256);
     
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;

        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) =
            target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance =
            token.allowance(address(this), spender).add(value);
        callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance =
            token.allowance(address(this), spender).sub(
                value,
                "SafeERC20: decreased allowance below zero"
            );
        callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {
            // Return data is optional

            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

/**
 * a contract must implement this interface in order to support relayed transaction.
 * It is better to inherit the BaseRelayRecipient as its implementation.
 */
abstract contract IRelayRecipient {

    /**
     * return if the forwarder is trusted to forward relayed transactions to us.
     * the forwarder is required to verify the sender's signature, and verify
     * the call is not a replay.
     */
    function isTrustedForwarder(address forwarder) public virtual view returns(bool);

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, then the real sender is appended as the last 20 bytes
     * of the msg.data.
     * otherwise, return `msg.sender`
     * should be used in the contract anywhere instead of msg.sender
     */
    function _msgSender() internal virtual view returns (address payable);

    function versionRecipient() external virtual view returns (string memory);
}
/**
 * A base contract to be inherited by any contract that want to receive relayed transactions
 * A subclass must use "_msgSender()" instead of "msg.sender"
 */
abstract contract BaseRelayRecipient is IRelayRecipient {

    /*
     * Forwarder singleton we accept calls from
     */
    address public trustedForwarder;

    /*
     * require a function to be called through GSN only
     */
    modifier trustedForwarderOnly() {
        require(msg.sender == address(trustedForwarder), "Function can only be called through the trusted Forwarder");
        _;
    }

    function isTrustedForwarder(address forwarder) public override view returns(bool) {
        return forwarder == trustedForwarder;
    }

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, return the original sender.
     * otherwise, return `msg.sender`.
     * should be used in the contract anywhere instead of msg.sender
     */
    function _msgSender() internal override virtual view returns (address payable ret) {
        if (msg.data.length >= 24 && isTrustedForwarder(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // so we trust that the last bytes of msg.data are the verified sender address.
            // extract sender address from the end of msg.data
            assembly {
                ret := shr(96,calldataload(sub(calldatasize(),20)))
            }
        } else {
            return msg.sender;
        }
    }
}

/**
 * WolfyStreetBets v.1.0.0 
 * Copyright (C) 2020 WolfyStreetBets.com
 * See LICENSE.MD for usage rights
 */

contract WolfyStreetBetsV1 is Ownable, ReentrancyGuard, BaseRelayRecipient {

    using SafeMath for uint256;
    using SafeMath for int;
    using SafeERC20 for IERC20;

    constructor(address _trustedForwarder, address _token) public {
        trustedForwarder = _trustedForwarder;
        TOKEN = IERC20(_token);
    }

    struct LiquidityDetails {
        uint256 _lowRisk;
        uint256 _highRisk;
        address _address;
        uint256 timestamp;
        bool isLowRisk;
        bool isWithdraw;
        bool isLoss;       
    }

    LiquidityDetails[] tempRecordForloss;
    LiquidityDetails[] LiquidityDetailsRecord;
    LiquidityDetails liquidityDetailsOwner;

    struct RewardPaid {
        uint256 rewardPaid;
        uint256 rewardPaidDate;
        bool isWithdraw;
    }

    struct ResultRecord {
        bool isLowRisk;
        bool marketWin;
    }

    ResultRecord[] public previousResultRecord;

    uint256 public poolStartTime = 0;
    uint256 public liquidityCycleStartTime = 0;
    uint256 public predictionAsset1; 
    uint256 public predictionAsset2;
    uint256 public netPredictionAsset1;
    uint256 public netPredictionAsset2;
    uint256 public ledgerL;
    uint256 public ledgerH;
    uint256 public winFactorH;
    uint256 public winFactorL; 
    uint256 public winnerScale;
    uint256 public totalLiquidityLowRisk;
    uint256 public totalLiquidityHighRisk;
    uint256 public liquidityRewardCollectedLowRisk;
    uint256 public liquidityRewardCollectedHighRisk;
    uint256 public liquidityReward = 20;

    bool public poolStarted;
    bool public liquidityCycle = true;
    bool private isWin;
    bool private checker;
    bool private A;
    bool private B;

    address[] _lowRiskUsers;
    address[] _highRiskUsers;
    address[] LiquidityLRUsers;
    address[] LiquidityHRUsers;
  
    IERC20 public TOKEN;

    mapping(address => mapping(bool => uint256)) private _poolBalances;
    mapping(address =>  mapping(bool => uint256)) public _losingStakers;
    mapping(address =>  mapping(bool => uint256)) public _profitStakers;
    mapping(address => uint256) currentLowLiquidity;
    mapping(address => uint256) currentHighLiquidity; 
    mapping(address => uint256) userLPReward;
    mapping (address => RewardPaid[]) rewardPaidRecord;

    /**
     * @dev poolStopped => liquidityCycle = true; => 12hr "liquidity cycle"
     * @dev timebox for "natural" liquidity change in pools whereby LPs can withdraw liquidity
     * @dev liquidity can be ADDED anytime, but withdrawn only during liquidityCycle = True; 
     * @dev post window => pool liquidity is locked until the next cycle, providing a stable liquid market
     * @dev liquidityCycle also allows predictors additional time to analyse before deciding on market participation 
     */

    /**
    * @dev Updates trusted forwarder should biconomy upgrades occur.
    */
    function setTrustedForwarder(address _trustedForwarder) public view onlyOwner {
        require (_trustedForwarder != address(0), "Address cannot be 0x0");
        require (_trustedForwarder != address(this), "Address cannot be contract address");
    }

    /**
    * @dev Overrides Context _msgSender() to use BaseRelayRecipient _msgSender() thereby enabling meta transactions when trustedForwarder is caller.
    */
    function _msgSender() internal override(Context, BaseRelayRecipient) view returns (address payable) {
       return BaseRelayRecipient._msgSender();
    }
    
    /** 
     * Override this function.
     * This version is to keep track of BaseRelayRecipient you are using
     * in your contract. 
     */
    function versionRecipient() external view override returns (string memory) {
        return "1";
    }
    
    /**
    * @dev Sets win requirement for low risk (LR) predictions as a multiplier.
    */
    function setwinFactorL(uint256 _winFactorL) public onlyOwner {
        require(poolStarted == false, "Pool has already been started!");
        winFactorL =  _winFactorL;
    }

    /**
    * @dev Sets win requirement for high risk (HR) predictions as a multiplier.
    */
    function setwinFactorH(uint256 _winFactorH) public onlyOwner {
        require(poolStarted == false, "Pool has already been started!");
        winFactorH = _winFactorH;
    }

    /**
    * @dev Stores user info.
    */
    function storeUsers(address receiver, address[] storage arrayData) internal {
        for (uint i = 0; i < arrayData.length; i++){
            if (arrayData[i] == receiver) {
                checker = true;
            } 
            else {
                checker = false;
            }
        }
            if (checker == false) {
                arrayData.push(receiver) ;
            }
    }

    /**
    * @dev Starts a prediction pool.
    * @param _predictionAsset1 current price of prediction asset 1 (uint256)
    * @param _predictionAsset2 current price of prediction asset 2 (uint256)
    */
    function startPool(uint256 _predictionAsset1, uint256 _predictionAsset2) public onlyOwner {            
        require(!poolStarted, "Previous pool not finalized yet");
        require(totalLiquidityLowRisk + liquidityDetailsOwner._lowRisk > 0 ," Low Risk Pool: Please add liquidity");
        require(totalLiquidityHighRisk + liquidityDetailsOwner._highRisk > 0 ," High Risk Pool: Please add liquidity");
        // 30 minutes for testing ONLY
        require(block.timestamp > liquidityCycleStartTime.add(30 minutes), "Cannot start pool during liquidity cycle");
        // PLEASE UNCOMMENT ME FOR MAINNET
        // require(block.timestamp > liquidityCycleStartTime.add(12 hours), "Cannot start pool during liquidity cycle");

        predictionAsset1 = _predictionAsset1;
        predictionAsset2 = _predictionAsset2;
       
        poolStartTime = block.timestamp;
        poolStarted = true;

        liquidityCycle = false;
    }
   
    /**
    * @dev Stops a prediction pool.
    * @param _predictionAsset1 current price of prediction asset 1 (uint256)
    * @param _predictionAsset2 current price of prediction asset 2 (uint256)
    */
    function stopPool(uint256 _predictionAsset1, uint256 _predictionAsset2) public onlyOwner { 
        // PLEASE UNCOMMENT ME FOR MAINNET
        // require(block.timestamp > poolStartTime.add(7 days), "Can stop after 7 days"); ### 7 days #### Mainnet        
        require(poolStarted, "Pool has not been started!");
    
        (netPredictionAsset1, A) = raisePercent(predictionAsset1,_predictionAsset1);
        (netPredictionAsset2, B)  = raisePercent(predictionAsset2,_predictionAsset2);
        
        checkPerformance(netPredictionAsset1, netPredictionAsset2, A, B);
       
        rewardManager(winnerScale, isWin);
        poolStarted = false;
        liquidityCycle = true;
        liquidityCycleStartTime = block.timestamp;
    }

    /**
    * @dev Stake an amount in a pool. 2% LP fee.
    * @param _amount (uint256)
    * @param _isLowRisk stake in low risk or high risk pool
    */
    function stake(uint256 _amount, bool _isLowRisk) public {        
        require(_amount > 0 , "You can't stake with 0. Choose an amount!");
        require(poolStarted, "Cannot stake until pool has been started!");
        // FOR MAINNET PLEASE UNCOMMENT ME
        // require(block.timestamp <= poolStartTime.add(12 hours),"12 hour staking window has now passed!" ); // Can stake upto 12 hours from start pool.

        uint256 stakeAmount;

        if (liquidityReward >= 1) {
          stakeAmount = _amount.sub(((_amount.mul(liquidityReward)).div(100)).div(10));
        }
        else {
          stakeAmount = _amount;
        }
        if (_isLowRisk) {    
            require(ledgerL.add(stakeAmount) <= (totalLiquidityLowRisk + liquidityDetailsOwner._lowRisk).mul(6), "Low risk pool: Staking limit reached!");   
            require(_poolBalances[_msgSender()][_isLowRisk].add(stakeAmount) <= (totalLiquidityLowRisk + liquidityDetailsOwner._lowRisk).mul(6), "Low risk pool: Staking limit reached!");
            liquidityRewardCollectedLowRisk += ((_amount.mul(liquidityReward)).div(100)).div(10);
            ledgerL += stakeAmount;
        } 
        else {
            require(ledgerH.add(stakeAmount) <= (totalLiquidityHighRisk + liquidityDetailsOwner._highRisk).mul(3), "High risk pool: Staking limit reached!");
            require(_poolBalances[_msgSender()][_isLowRisk].add(stakeAmount) <= (totalLiquidityHighRisk + liquidityDetailsOwner._highRisk).mul(3), "High risk pool: Staking limit reached!");
            liquidityRewardCollectedHighRisk += ((_amount.mul(liquidityReward)).div(100)).div(10);
            ledgerH += stakeAmount;
        }
        _isLowRisk == true ? storeUsers(_msgSender(), _lowRiskUsers): storeUsers(_msgSender(), _highRiskUsers); 
        _poolBalances[_msgSender()][_isLowRisk] += stakeAmount;
        TOKEN.safeTransferFrom(_msgSender(), address(this), _amount);        

        distributeLiquidityRewards(true);
        distributeLiquidityRewards(false);
    }

    /**
    * @dev Check owner liquidity provisioned, and payout from here first.
    * @param _factor winning factor / multiplier (uint256)
    * @param _res win or loss (bool)
    */
    function payoutOwnerLiquidity(uint256 _factor, bool _res) internal {
        uint256 totalWinLowRisk;
        uint256 totalWinHighRisk;

        if (_factor >= winFactorL && _res == true) {
            // LR | PROFIT => +12%
            for (uint i = 0 ; i < _lowRiskUsers.length; i++)
            {           
                totalWinLowRisk += _poolBalances[_lowRiskUsers[i]][true].mul(120).div(1000);
            }
        } 
      
        if (_factor >= winFactorH && _res == true) {     
            // HR | PROFIT => +30%
            for (uint i = 0 ; i < _highRiskUsers.length ; i++){
                totalWinHighRisk += _poolBalances[_highRiskUsers[i]][false].mul(300).div(1000);
            }
        } 
      
        if (totalWinHighRisk >= liquidityDetailsOwner._highRisk) {          
            uint256 cloneTotalLiquidityHighRisk = totalLiquidityHighRisk;
            uint256 diffrenceTobePaidHighRisk = totalWinHighRisk.sub(liquidityDetailsOwner._highRisk);
            for (uint256 i=0;i<LiquidityHRUsers.length;i++) {              
                uint256 deductionPercentage = (currentHighLiquidity[LiquidityHRUsers[i]].mul(100))/cloneTotalLiquidityHighRisk;        
                uint256 amount = (diffrenceTobePaidHighRisk.mul(deductionPercentage)).div(100);               
                currentHighLiquidity[LiquidityHRUsers[i]] -= amount;               
                tempRecordForloss.push(LiquidityDetails(0,amount,LiquidityHRUsers[i],block.timestamp,false,false,true));              
                totalLiquidityHighRisk -= amount;
            }
            for (uint256 i=0;i<tempRecordForloss.length;i++) {
                LiquidityDetailsRecord.push(tempRecordForloss[i]);
            }
             
            liquidityDetailsOwner._highRisk = 0;
            delete tempRecordForloss;
            
        }
        if (totalWinLowRisk >= liquidityDetailsOwner._lowRisk) {
             uint256 diffrenceTobePaidLowRisk = totalWinLowRisk.sub(liquidityDetailsOwner._lowRisk);
             uint256 clonetotalLiquidityLowRisk =totalLiquidityLowRisk;
            for (uint256 i=0;i<LiquidityLRUsers.length;i++) {
                uint256 deductionPercentage = (currentLowLiquidity[LiquidityLRUsers[i]].mul(100))/clonetotalLiquidityLowRisk;
                uint256 amount =  (diffrenceTobePaidLowRisk.mul(deductionPercentage)).div(100);                 
                currentLowLiquidity[LiquidityLRUsers[i]] -= amount;                
                tempRecordForloss.push(LiquidityDetails(amount,0,LiquidityLRUsers[i],block.timestamp,true,false,true));
                totalLiquidityLowRisk -= amount;
                
            }
            for (uint256 i=0;i<tempRecordForloss.length;i++) {
                LiquidityDetailsRecord.push(tempRecordForloss[i]);
            }
          
            liquidityDetailsOwner._lowRisk = 0;
            delete tempRecordForloss;
        }              
    }
    
    /**
    * @dev Update pool records based on result.
    * @param _factor winning factor / multiplier (uint256)
    * @param _res win or loss (bool)
    */
    function rewardManager(uint256 _factor, bool _res) internal {      
        payoutOwnerLiquidity(_factor,_res);
        if (_factor >= winFactorL && _res == true) {
            // LR | PROFIT => +12%
            for (uint i = 0 ; i < _lowRiskUsers.length ; i++) {           
                if (liquidityDetailsOwner._lowRisk >= _poolBalances[_lowRiskUsers[i]][true].mul(120).div(1000)) {
                    liquidityDetailsOwner._lowRisk -= _poolBalances[_lowRiskUsers[i]][true].mul(120).div(1000);
                    _profitStakers[_lowRiskUsers[i]][true] += _poolBalances[_lowRiskUsers[i]][true].mul(120).div(1000);              
                    _poolBalances[_lowRiskUsers[i]][true] += _poolBalances[_lowRiskUsers[i]][true].mul(120).div(1000);
                    previousResultRecord.push(ResultRecord(true,true));
                }
                else {
                    liquidityDetailsOwner._lowRisk = 0;
                    _profitStakers[_lowRiskUsers[i]][true] += _poolBalances[_lowRiskUsers[i]][true].mul(120).div(1000);               
                    _poolBalances[_lowRiskUsers[i]][true] += _poolBalances[_lowRiskUsers[i]][true].mul(120).div(1000);
                    previousResultRecord.push(ResultRecord(true,true));
                }       
            }         
        } 
        else {
            // LR | LOSS => -15%
            for (uint i = 0 ; i < _lowRiskUsers.length ; i++){
                liquidityDetailsOwner._lowRisk += _poolBalances[_lowRiskUsers[i]][true].mul(150).div(1000);
                _losingStakers[_lowRiskUsers[i]][true] += _poolBalances[_lowRiskUsers[i]][true].mul(150).div(1000);
                _poolBalances[_lowRiskUsers[i]][true] -= _poolBalances[_lowRiskUsers[i]][true].mul(150).div(1000);
                previousResultRecord.push(ResultRecord(true,false));
            }     
        }

        // HR wl  
        if (_factor >= winFactorL && _res == true) {         
            // HR | PROFIT => +30%
            for (uint i = 0 ; i < _highRiskUsers.length ; i++){               
                if (liquidityDetailsOwner._highRisk >= _poolBalances[_highRiskUsers[i]][false].mul(300).div(1000)) {
                    liquidityDetailsOwner._highRisk -= _poolBalances[_highRiskUsers[i]][false].mul(300).div(1000);                    
                    _profitStakers[_highRiskUsers[i]][false] += _poolBalances[_highRiskUsers[i]][false].mul(300).div(1000);
                    _poolBalances[_highRiskUsers[i]][false] += _poolBalances[_highRiskUsers[i]][false].mul(300).div(1000);
                    previousResultRecord.push(ResultRecord(false,true));
                }
                else {
                    liquidityDetailsOwner._highRisk = 0;                   
                    _profitStakers[_highRiskUsers[i]][false] += _poolBalances[_highRiskUsers[i]][false].mul(300).div(1000);
                    _poolBalances[_highRiskUsers[i]][false] += _poolBalances[_highRiskUsers[i]][false].mul(300).div(1000);
                    previousResultRecord.push(ResultRecord(false,true));
                }
            }           
        } 
        else {
            // HR | LOSS => -35%
            for (uint i = 0 ; i < _highRiskUsers.length ; i++) {
                liquidityDetailsOwner._highRisk += _poolBalances[_highRiskUsers[i]][false].mul(350).div(1000);       
                _losingStakers[_highRiskUsers[i]][false] += _poolBalances[_highRiskUsers[i]][false].mul(350).div(1000);
                _poolBalances[_highRiskUsers[i]][false] -= _poolBalances[_highRiskUsers[i]][false].mul(350).div(1000);
                previousResultRecord.push(ResultRecord(false,false));     
            }
        }
    }

    /**
    * @dev Checks and sets win/loss status for market.
    * @param _inputPredictionAsset1 current price of prediction asset 1
    * @param _inputpredictionAsset2 current price prediction of asset 2
    * @param _polarityPredictionAsset1 appreciation or depreciation 
    * @param _polaritypredictionAsset2 appreciation or depreciation
    */
    function checkPerformance(uint256 _inputPredictionAsset1, uint256 _inputpredictionAsset2, bool _polarityPredictionAsset1, bool _polaritypredictionAsset2) public {       
        if (!_polarityPredictionAsset1 && !_polaritypredictionAsset2) { 
            if (_inputPredictionAsset1 > _inputpredictionAsset2){
                winnerScale = _inputPredictionAsset1.mul(10).div(_inputpredictionAsset2);
                isWin = false;            
            } 
            else {
                winnerScale = _inputpredictionAsset2.mul(10).div(_inputPredictionAsset1);
                isWin = true;               
            }
        } 
        else if (_polaritypredictionAsset2 && !_polaritypredictionAsset2) {  
            winnerScale = _inputPredictionAsset1.add(_inputpredictionAsset2).mul(10).div(_inputPredictionAsset1);
            isWin = true;           
        }
        else if (!_polarityPredictionAsset1 && _polaritypredictionAsset2) {       
            winnerScale = _inputPredictionAsset1.add(_inputpredictionAsset2).mul(10).div(_inputpredictionAsset2);
            isWin = false;  
        }
        else if (_polarityPredictionAsset1 && _polaritypredictionAsset2) {            
            if (_inputPredictionAsset1 > _inputpredictionAsset2){
                winnerScale = _inputPredictionAsset1.mul(10).div(_inputpredictionAsset2);
                isWin = true;           
            } 
            else {
                winnerScale = _inputpredictionAsset2.mul(10).div(_inputPredictionAsset1);
                isWin = false;
            }
        } 
        else {
            winnerScale = 0;
            isWin = false;
        }
    }

    /**
    * @dev Withdraw a stake from a market.
    * @param _amount (uint256)
    * @param _isLowRisk risk pool (bool)
    */
    function withdrawPredictionStake(uint256 _amount, bool _isLowRisk) public nonReentrant {
        require(!poolStarted, "Cannot withdraw Asset while pool is running");
        require(_msgSender() != owner());
        require(_amount <= _poolBalances[_msgSender()][_isLowRisk], "Insufficient Balance");
        _poolBalances[_msgSender()][_isLowRisk] -= _amount;
        TOKEN.safeTransfer(_msgSender(), _amount);

        if (_isLowRisk) {
            ledgerL -= _amount;
        } 
        else {
            ledgerH -= _amount;
        }   
    }

    /**
    * @dev Handles appreciation/depreciation.
    * @param _v1 (uint256)
    * @param _v2 (uint256)
    */
    function raisePercent(uint256 _v1, uint256 _v2) internal pure returns (uint256, bool) {
        if (_v1 > _v2){
          return (_v1.sub(_v2).mul(1000) == 0 ? 0 : (_v1.sub(_v2).mul(1000).div(_v1)), false); //___| Deprecation |___
       } 
       else {
          return (_v2.sub(_v1).mul(1000) == 0 ? 0 : (_v2.sub(_v1).mul(1000).div(_v1)), true); //___| Appreciation |___
       } 
    }  

    /**
    * @dev Add liquidity to a market.
    * @param amount (uint256)
    * @param _isLowRisk (bool)
    */
    function provideLiquidity(uint256 amount, bool _isLowRisk) public {
        if (_msgSender() != owner()) {
            if (_isLowRisk) {
                LiquidityDetailsRecord.push(LiquidityDetails(amount,0,_msgSender(),block.timestamp,true,false,false));
            }
            else {
                LiquidityDetailsRecord.push(LiquidityDetails(0,amount,_msgSender(),block.timestamp,false,false,false));
            }
            if (_isLowRisk == true) {
                totalLiquidityLowRisk += amount;
                currentLowLiquidity[_msgSender()] += amount;
                storeUsers(_msgSender(),LiquidityLRUsers);
            
            }
            else {
                totalLiquidityHighRisk += amount;
                currentHighLiquidity[_msgSender()] += amount;
                storeUsers(_msgSender(),LiquidityHRUsers);
            }
            
        }
         if (_msgSender() == owner() && _isLowRisk) {
            liquidityDetailsOwner._address = owner();
            liquidityDetailsOwner._lowRisk += amount;
        }
        else if (_msgSender() == owner() && _isLowRisk == false) {
            liquidityDetailsOwner._address = owner();
            liquidityDetailsOwner._highRisk += amount;
        }
        TOKEN.safeTransferFrom(_msgSender(), address(this), amount);       
    }

    /**
    * @dev Withdraw liquidity from a market.
    * @param _amount (uint256)
    * @param _isLowRisk (bool)
    */
    function withdrawLiquidity(uint256 _amount, bool _isLowRisk) external nonReentrant {
        require(_amount > 0 , "Choose an amount!");
        require(liquidityCycle, "Cannot withdraw liquidity outside of the liquidity cycle!");
        // 30 minutes for testing ONLY
        require(block.timestamp <= liquidityCycleStartTime.add(30 minutes),"liquidity cycle has now passed!" ); 
        // PLEASE UNCOMMENT FOR MAINNET
        // require(block.timestamp <= liquidityCycleStartTime.add(12 hours),"12 hour liquidity cycle has now passed!" ); 
        if (_isLowRisk) {
            require(_amount <= currentLowLiquidity[_msgSender()],"Insufficient Balance");
            currentLowLiquidity[_msgSender()] -= _amount;
            totalLiquidityLowRisk -= _amount;
            LiquidityDetailsRecord.push(LiquidityDetails(_amount,0,_msgSender(),block.timestamp,true,true,false));
            TOKEN.safeTransfer(_msgSender(), _amount);           
        }
        else {
            require(_amount <= currentHighLiquidity[_msgSender()],"Insufficient Balance");
            currentHighLiquidity[_msgSender()] -= _amount;
            LiquidityDetailsRecord.push(LiquidityDetails(0,_amount,_msgSender(),block.timestamp,false,true,false));
            totalLiquidityHighRisk -= _amount;
            TOKEN.safeTransfer(_msgSender(), _amount);
        }
    }

    /**
    * @dev Distribute LP rewards. Called on every Stake() call for immediate distribution/withdrawal availability.
    * @param _isLowRisk (bool)
    */   
    function  distributeLiquidityRewards(bool _isLowRisk) internal {
        for (uint i=0;i<LiquidityDetailsRecord.length;i++) {
            if (_isLowRisk && LiquidityDetailsRecord[i].isLowRisk == true) {
                uint256 rewardPerc = ((LiquidityDetailsRecord[i]._lowRisk.mul(10**decimals())).mul(100*10**decimals())).div(totalLiquidityLowRisk.mul(10**decimals()));              
                uint256 rewardAmount = ((liquidityRewardCollectedLowRisk.mul(10**decimals()) ).mul(rewardPerc) )/(100 * 10**decimals());         
                rewardPaidRecord[LiquidityDetailsRecord[i]._address].push(RewardPaid(rewardAmount.div(10**decimals()),block.timestamp,false));              
                userLPReward[LiquidityDetailsRecord[i]._address] += rewardAmount;
            }
            else if (_isLowRisk == false && LiquidityDetailsRecord[i].isLowRisk == false) {
                uint256 rewardPerc = ((LiquidityDetailsRecord[i]._highRisk.mul(10**decimals())).mul(100*10**decimals())).div(totalLiquidityHighRisk.mul(10**decimals()));
                uint256 rewardAmount = ((liquidityRewardCollectedHighRisk.mul(10**decimals()) ).mul(rewardPerc) )/(100 * 10**decimals());               
                rewardPaidRecord[LiquidityDetailsRecord[i]._address].push(RewardPaid(rewardAmount.div(10**decimals()),block.timestamp,false));               
                userLPReward[LiquidityDetailsRecord[i]._address] += rewardAmount;
            }
        }
        if (_isLowRisk) {
            liquidityRewardCollectedLowRisk = 0;
        }
        else {
            liquidityRewardCollectedHighRisk = 0;
        }
        
    }
    
    /**
    * @dev Withdraw LP rewards. 
    * @param amount (uint256)
    */  
    function withdrawLiquidityRewards(uint256 amount) external nonReentrant {
        require(amount<=userLPReward[_msgSender()],"Insufficient Balance");
        userLPReward[_msgSender()] = userLPReward[_msgSender()].sub(amount.mul(10**decimals())); 
        TOKEN.safeTransfer(_msgSender(),amount);
        rewardPaidRecord[_msgSender()].push(RewardPaid(amount,block.timestamp,true));       
    }

    /**
    * @dev Gets liquidity-specific amounts/stats. 
    * @return totalLiq totalLiquidity in both low & high risk pools (uint256)
    * @return totalLPFees total LP fees that have been collected (uint256)
    */
    function getLiquidityStatTotals() external view returns (uint256 totalLiq, uint256 totalLPFees) {
        uint256 totalLiquidity;
        uint256 totalLPFeesCollected;

        totalLiquidity = totalLiquidityLowRisk.add(totalLiquidityHighRisk);
        totalLPFeesCollected = liquidityRewardCollectedLowRisk.add(liquidityRewardCollectedHighRisk);

        return (totalLiquidity, totalLPFeesCollected);
    }

    /**
    * @dev Gets liquidity-specific amounts/stats per user. 
    * @return LPFeesCollected total LP fees that have been collected by a user (uint256)
    * @return LRLiq user liquidity in low risk pool (uint256)
    * @return HRLiq user liquidity in high risk pool (uint256)
    */
    function getLiquidityStatsPerUser() external view returns (uint256 LPFeesCollected, uint256 LRLiq, uint256 HRLiq) {
        return (userLPReward[_msgSender()].div(10**decimals()), currentLowLiquidity[_msgSender()], currentHighLiquidity[_msgSender()]);
    }

    /**
    * @dev Gets liquidity-specific amounts/stats for the contract owner. 
    * @return oTotalLiq owner's totalLiquidity in both low & high risk pools (uint256)
    * @return oLRLiq owner liquidity in low risk pool (uint256)
    * @return oHRLiq owner liquidity in high risk pool (uint256)
    */
    function getOwnerLiquidityStats() external view returns (uint256 oTotalLiq, uint256 oLRLiq, uint256 oHRLiq) {
        return (liquidityDetailsOwner._lowRisk.add(liquidityDetailsOwner._highRisk), liquidityDetailsOwner._lowRisk, liquidityDetailsOwner._highRisk);
    }

    /**
    * @dev Calculates prediction market earnings (wins - losses) per user. 
    * @return calculatedEarnings owner's totalLiquidity in both low & high risk pools (uint256)
    */
    function calculateEarnings (bool _isLowRisk) internal view returns (uint256) {
        uint256 calculatedEarnings;
        if (_profitStakers[_msgSender()][_isLowRisk] > _losingStakers[_msgSender()][_isLowRisk]) {
            calculatedEarnings = _profitStakers[_msgSender()][_isLowRisk].sub(_losingStakers[_msgSender()][_isLowRisk]);
            return calculatedEarnings;
        }
        else {
            return 0;
        }       
    }

    /**
    * @dev Gets prediction market details (stats) per user. 
    * @return profit (uint256)
    * @return loss (uint256)#
    * @return net profit - loss (uint256)
    * @return poolBal current balance in pool (uint256)
    */
    function getPredictionStatsPerUser(bool _isLowRisk) external view returns (uint256 profit, uint256 loss, uint256 net, uint256 poolBal) {
        return (_profitStakers[_msgSender()][_isLowRisk], _losingStakers[_msgSender()][_isLowRisk], calculateEarnings(_isLowRisk), _poolBalances[_msgSender()][_isLowRisk]);
    }

    /**
    * @dev Gets total staked in low risk & high risk pools. 
    * @return total staked (uint256)
    */
    function getTotalStaked() external view returns (uint256) {
        return ledgerL.add(ledgerH); 
    }

    /**
    * @dev Gets previous results. 
    * @return results (bool _isLowRisk, bool marketWin) (array)
    */
    function getPreviousResultList() public view returns (ResultRecord[] memory) {
        return previousResultRecord;
    }

    /**
    * @dev Gets predictor count in both low risk & high risk pools. 
    * @return (uint256)
    */
    function getPredictorCount() external view returns (uint256) {
        uint256 lrCount;
        uint256 hrCount;

        lrCount = _lowRiskUsers.length;
        hrCount = _highRiskUsers.length;

        return lrCount.add(hrCount);
    }

    /**
    * @dev Gets token decimals. 
    * @return (uint256)
    */
    function decimals() public view returns(uint256) {
        return TOKEN.decimals();
    }
}