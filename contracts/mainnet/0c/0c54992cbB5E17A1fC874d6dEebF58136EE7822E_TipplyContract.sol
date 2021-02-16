/**
 *Submitted for verification at Etherscan.io on 2021-02-15
*/

// File: @openzeppelin/contracts-ethereum-package/contracts/Initializable.sol

pragma solidity >=0.4.24 <0.7.0;


/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

// File: @openzeppelin/contracts-ethereum-package/contracts/GSN/Context.sol

pragma solidity ^0.6.0;


/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract ContextUpgradeSafe is Initializable {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.

    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {


    }


    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }

    uint256[50] private __gap;
}

// File: @openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol

pragma solidity ^0.6.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract OwnableUpgradeSafe is Initializable, ContextUpgradeSafe {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */

    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {


        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);

    }


    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    uint256[49] private __gap;
}

// File: contracts/TipplyContract.sol

pragma solidity >=0.5.0 <0.8.0;




interface IERC20 {

    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

}



library SafeMath {
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
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
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }
}


interface IUniswapV2Pair{
    
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
} 

interface IUniswapV2Router02{
    
    
     function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    
    
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
}


contract TipplyContract is OwnableUpgradeSafe {
    
    using SafeMath for uint256;
    enum tx_Type { ETH,DYT,ENJ}
    
    address payable _recipient;
    address public UniSwap_Address;
    address public WETH;
    address public EthToDYT;
    address public ENJ_Address;
    address public EthToEnj;
    address public DYT_Address;

    mapping (address=>bool) whiteListed;

    event MintFeeDeducted(address sender , uint256 ethAmount , uint256 enjAmount);
    event WithdrawFeeDeducted(address sender  , string _type , uint256 amount);
    event DepositFeeDeducted(address sender  , string _type , uint256 amount);
    

    function initialize(address payable recipient) external initializer {
        OwnableUpgradeSafe.__Ownable_init();
        _recipient = recipient;
        whiteListed[msg.sender] = true;
        UniSwap_Address = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        EthToDYT = 0x5B7aD60A92e725597e4A28444d498d1999cF66b6;
        EthToEnj = 0xE56c60B5f9f7B5FC70DE0eb79c6EE7d00eFa2625;
        ENJ_Address = 0xF629cBd94d3791C9250152BD8dfBDF380E2a3B9c;
        DYT_Address = 0x740623d2c797b7D8D1EcB98e9b4Afcf99Ec31E14;
    }
    

    function isWhiteListed(address _address) external view returns(bool) {
        return whiteListed[_address];
    }

    function changeRecipient(address payable newrecipient) onlyOwner external{
        _recipient = newrecipient;
    } 
    
    function whiteListAddress(address _admin) external onlyOwner{
        require(whiteListed[_admin]!=true,"Already whiteListed");
        whiteListed[_admin] = true;
    }
    
    function blackListAddress(address _admin) external onlyOwner{
        require(whiteListed[_admin]==true,"address not whiteListed");
        whiteListed[_admin] = false;
    }

    function transferMintFeas(uint256 amount) external payable {
        require(amount>0,"Cant transfer 0 amount");
        require(amount<=IERC20(ENJ_Address).balanceOf(msg.sender),"Sender does not have enough ENJ");
        IERC20(ENJ_Address).transferFrom(msg.sender,_recipient,amount);
        _recipient.call{value: msg.value}("");
        emit MintFeeDeducted(msg.sender , msg.value , amount);
    }
    
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }
    
    function withdrawAmount(uint256 amount , tx_Type option , uint8 v, bytes32 r, bytes32 s ,uint256 deadline , address sender ) external payable {
        require(deadline >= block.timestamp, "Tipply Contract:: AUTH_EXPIRED");
        require(msg.sender==sender,"sender must be msg.sender");
        require(amount>0,"Cant withdraw 0 amount");
        bytes32 encodeData = keccak256(abi.encode(sender, amount,option,deadline,userNonce[sender]));
        require(hashGenerated[encodeData]==false,"Same hash cannot be used twice");
        hashGenerated[encodeData] = true;
        userNonce[sender] = userNonce[sender].add(1);
        _validateSignedData(_recipient, encodeData, v, r, s);
        if(option == tx_Type.ETH){
             sender.call{value: amount}("");
             emit WithdrawFeeDeducted(sender , 'ETH' , amount);
        }
        else if(option == tx_Type.DYT){
            IERC20(DYT_Address).transfer(sender,amount);
            emit WithdrawFeeDeducted(sender  , 'DYT' , amount);
        }
        
        else if(option == tx_Type.ENJ){
            IERC20(ENJ_Address).transfer(sender,amount);
            emit WithdrawFeeDeducted(sender , 'ENJ' , amount);
        }
    }
    
    function depositAmount(uint256 amount , tx_Type option) external payable {
        require(amount>0,"Cant deposit 0 amount");
        if(option == tx_Type.ETH){
            // require(msg.value <= address(msg.sender).balance,"Sender does not have enough ETH funds ");
            address(this).call{value: msg.value}("");

            emit DepositFeeDeducted(msg.sender , 'ETH' , msg.value);
        }
        
        else if(option == tx_Type.DYT){
            require(IERC20(DYT_Address).balanceOf(msg.sender)>=amount,"Sender does not have enough DYT funds ");
            IERC20(DYT_Address).transferFrom(msg.sender,address(this),amount);
            emit DepositFeeDeducted(msg.sender  , 'DYT' , amount);
        }
        
        else if(option == tx_Type.ENJ){
            require(IERC20(ENJ_Address).balanceOf(msg.sender)>=amount,"Sender does not have enough ENJ funds ");
            IERC20(ENJ_Address).transferFrom(msg.sender,address(this),amount);
            emit DepositFeeDeducted(msg.sender , 'ENJ' , amount);
        }
       
    }
    
    function batchTransfer(address[] calldata recipients ,uint256[] calldata dytAmount ,uint256[] calldata ethAmount, uint256[] calldata enjAmount) external {
        require(whiteListed[msg.sender]==true,"Sender not White Listed");
        for(uint256 i=0;i<recipients.length;i++){
            if(dytAmount[i]>0){
            IERC20(DYT_Address).transfer(recipients[i],dytAmount[i]);
            }
            if(enjAmount[i]>0){
            IERC20(ENJ_Address).transfer(recipients[i],enjAmount[i]);
            }
            if(ethAmount[i]>0){
            recipients[i].call{value: ethAmount[i]}("");
            }
        }
    }
    
    function withdrawFunds(uint256 dytAmount , uint256 enjAmount , uint256 ethAmount) external {
        require(whiteListed[msg.sender]==true,"Sender not White Listed");
        if(enjAmount>0){
            IERC20(ENJ_Address).transfer(msg.sender,enjAmount);
        }
        if(dytAmount>0){
           IERC20(DYT_Address).transfer(msg.sender,dytAmount); 
        }
        if(ethAmount>0){
           msg.sender.call{value: ethAmount}("");
        }
    }
    
    
    function giveUniSwapApproval() external {
        require(whiteListed[msg.sender]==true,"Sender not White Listed");
        IERC20(ENJ_Address).approve(UniSwap_Address,uint(-1));
        IERC20(WETH).approve(UniSwap_Address,uint(-1));
    }
    
     function swapETHtoDYT(uint256 ethAmount) external  {
        require(whiteListed[msg.sender]==true,"Sender not White Listed");
        address[] memory path;
        path = new address[](2);
        path[0] = WETH;
        path[1] = DYT_Address;
        
        (uint256 reserve1 , uint256 reserve2,) = IUniswapV2Pair(EthToDYT).getReserves();
        uint256 amountOut = getAmountOut(ethAmount,reserve2,reserve1);
        amountOut = amountOut.sub(amountOut.mul(2).div(100));
        uint256[] memory amounts = IUniswapV2Router02(UniSwap_Address)
            .swapExactETHForTokens{value:ethAmount}(
            amountOut,
            path,
            address(this),
            1839591241
        );
    }
    
    function swapENJtoDYT(uint256 enjAmount) external {
        require(whiteListed[msg.sender]==true,"Sender not White Listed");
        address[] memory path;
        path = new address[](3);
        path[0] = ENJ_Address;
        path[1] = WETH;
        path[2] = DYT_Address;
        
        (uint256 reserve1 ,,) = IUniswapV2Pair(EthToEnj).getReserves();
        (uint256 reserve2,,) = IUniswapV2Pair(EthToDYT).getReserves();
        uint256 amountOut = getAmountOut(enjAmount,reserve1,reserve2);
        amountOut = amountOut.sub(amountOut.mul(2).div(100));
        uint256[] memory amounts = IUniswapV2Router02(UniSwap_Address)
            .swapExactTokensForTokens(
            enjAmount,
            amountOut,
            path,
            address(this),
            1839591241
        );
    }
    
    fallback() external payable{
        
        
    }
    bytes32 private constant EIP712DOMAIN_HASH = 0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;
    bytes32 private constant NAME_HASH = 0x345b72c36b14f1cee01efb8ac4b299dc7b8d873e28b4796034548a3d371a4d2f;
    bytes32 private constant VERSION_HASH = 0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6;
    mapping (address=>uint256) userNonce;
    mapping(bytes32=>bool) hashGenerated;


    
    
    function getDomainSeparator() public view returns (bytes32) {
        return keccak256(abi.encode(EIP712DOMAIN_HASH, NAME_HASH, VERSION_HASH, 4, address(this)));
    }
    
    function _validateSignedData(
        address signer,
        bytes32 encodeData,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal view {
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", getDomainSeparator(), encodeData));
        address recoveredAddress = ecrecover(digest, v, r, s);
        // Explicitly disallow authorizations for address(0) as ecrecover returns address(0) on malformed messages
        require(recoveredAddress != address(0) && recoveredAddress == signer, "TipplyContract:: INVALID_SIGNATURE");
    }

    function getUserNonce(address _user) public view returns(uint256){
        return userNonce[_user];
    }
}