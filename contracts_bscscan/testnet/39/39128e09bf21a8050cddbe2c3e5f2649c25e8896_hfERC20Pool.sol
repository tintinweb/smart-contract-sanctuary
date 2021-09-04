/**
 *Submitted for verification at BscScan.com on 2021-09-03
*/

pragma solidity ^0.5.17;

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
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
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


// File: @openzeppelin/contracts/math/Math.sol

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}


// File: @openzeppelin/contracts/GSN/Context.sol

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
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


// File: @openzeppelin/contracts/ownership/Ownable.sol
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    
    address private _owner;

    address private _oper;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    //event ControllerTransferred(address indexed previousController, address indexed newController);
    event OperTransferred(address indexed previousOper, address indexed newOper);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner  = _msgSender();
        //_farmer = _msgSender();
        //quota[_msgSender()] = 0x0;

        emit OwnershipTransferred(address(0), _owner);
        //emit FarmerTransferred(address(0), _farmer);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }


    /**
     * @dev Returns the address of the current oper.
     */
    function oper() public view returns (address) {
        return _oper;
    }


    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }


    /**
     * @dev Throws if called by any account other than the oper.
     */
    modifier onlyOper() {
        require(isOper(), "Ownable: caller is not the Oper");
        _;
    }


    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }


    /**
     * @dev Returns true if the caller is the current oper.
     */
    function isOper() public view returns (bool) {
        return _msgSender() == _oper;
    }


    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }


    /**
     * @dev Transfers farmer of the contract to a new account (`newOper`).
     * Can only be called by the current owner.
     */
    function transferOper(address newOper) public onlyOwner {
        _transferOper(newOper);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    
    /**
     * @dev Transfers farmer of the contract to a new account (`newOper`).
     */
    function _transferOper(address newOper) internal {
        require(newOper != address(0), "Ownable: newOper is the zero address");
        emit OperTransferred(_oper, newOper);
        _oper = newOper;
    }    
        
    
}


// File: @openzeppelin/contracts/math/SafeMath.sol
/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */



/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
interface IERC20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the token decimals.
   */
  function decimals() external view returns (uint8);

  /**
   * @dev Returns the token symbol.
   */
  function symbol() external view returns (string memory);

  /**
  * @dev Returns the token name.
  */
  function name() external view returns (string memory);

  /**
   * @dev Returns the bep token owner.
   */
  function getOwner() external view returns (address);

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
  function allowance(address _owner, address spender) external view returns (uint256);

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


/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * IMPORTANT: It is unsafe to assume that an address for which this
     * function returns false is an externally-owned account (EOA) and not a
     * contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}




/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */

library SafeERC20 {
    //TODO: Replace in deploy Script

    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {

        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
  
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}



contract IRewardDistributionRecipient is Ownable {
    address public rewardDistribution;

    function notifyRewardAmount(uint256 reward,uint256 new_DURATION,uint256 new_settlement_DURATION) external;

    modifier onlyRewardDistribution() {
        require(_msgSender() == rewardDistribution, "Caller is not reward distribution");
        _;
    }

    function setRewardDistribution(address _rewardDistribution)
        external
        onlyOwner
    {
        rewardDistribution = _rewardDistribution;
    }
}


contract LPTokenWrapper is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;


    IERC20 public tokenAddr;
    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;


    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }
    

    function stake(uint256 amount) public  {
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        tokenAddr.safeTransferFrom(msg.sender, address(this), amount);
    }

    function withdraw(uint256 amount) public {
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        tokenAddr.safeTransfer(msg.sender, amount);
    }

   
    /**
     * @dev set oper.
     */
    function setOper(address newOper) public  {
        transferOper(newOper);
    }
   
}


contract farmerDate {
    
    //using Address for address;
    
    mapping(string => uint8) public lFarmer;
    mapping(string => uint8) public mFarmer;
    mapping(string => uint8) public sFarmer;
    
    mapping(string => uint32) public pricePerAcre;
    
    mapping(string => uint32) public limitPerAcre;
    

    constructor() public {
        initFarmerDate();
    }
    
    function initFarmerDate() internal {
        
    lFarmer["BNB"]   = 200;
    lFarmer["CAKE"]  = 200;
    lFarmer["SUSHI"] = 100;
    lFarmer["UNI"]   = 100;
    lFarmer["1INCH"] = 100;
    lFarmer["LINK"]  = 100;
    lFarmer["EPS"]   = 50;
    lFarmer["ALPHA"] = 50;
    lFarmer["BUSD"]  = 50;
    lFarmer["USDT"]  = 50;
    
    mFarmer["SUSHI"] = 15;
    mFarmer["UNI"]   = 15;
    mFarmer["1INCH"] = 15;
    mFarmer["LINK"]  = 15;
    mFarmer["EPS"]   = 10;
    mFarmer["ALPHA"] = 10;
    mFarmer["BUSD"]  = 10;
    mFarmer["USDT"]  = 10;
    
    sFarmer["EPS"]   = 3;
    sFarmer["ALPHA"] = 3;
    sFarmer["BUSD"]  = 2;
    sFarmer["USDT"]  = 2;
    
    pricePerAcre["BNB"]   = 10000;
    pricePerAcre["CAKE"]  = 10000;
    pricePerAcre["SUSHI"] = 10000;
    pricePerAcre["UNI"]   = 10000;
    pricePerAcre["1INCH"] = 10000;
    pricePerAcre["LINK"]  = 10000;
    pricePerAcre["EPS"]   = 10000;
    pricePerAcre["ALPHA"] = 10000;
    pricePerAcre["BUSD"]  = 10000;
    pricePerAcre["USDT"]  = 10000;
    

    limitPerAcre["BNB"]   = 100;
    limitPerAcre["CAKE"]  = 1000;
    limitPerAcre["SUSHI"] = 2000;
    limitPerAcre["UNI"]   = 1000;
    limitPerAcre["1INCH"] = 10000;
    limitPerAcre["LINK"]  = 1000;
    limitPerAcre["EPS"]   = 100000;
    limitPerAcre["ALPHA"] = 1000;
    limitPerAcre["BUSD"]  = 1000;
    limitPerAcre["USDT"]  = 1000;
    
    
    }
    
    function getFarmerPoolSize(uint farmerType , string memory tokenName) public view returns(uint8) {
        //string memory tokenName = IERC20(supportTokenAddr).name(); 
        if (1 == farmerType){
            return sFarmer[tokenName];
        }
        else if (2 == farmerType){
            return mFarmer[tokenName];
        }
        else if (3 == farmerType){
            return lFarmer[tokenName];
        }
    }

}

contract PlayerStation  is farmerDate{
    
    using SafeMath for uint256;
     
    struct limitPerToken{
        uint256  totalLimit;
        uint256  usedLimit;
    }
    
    mapping(address => limitPerToken) private playerLimit;
    
    constructor() public {}
    
    function bePlayer(string memory  tokenName ,  uint256 buySize , uint256 amount) internal {
        
        require(pricePerAcre[tokenName] != 0);
        require(buySize.mul(pricePerAcre[tokenName]).mul(1e18) == amount);
        

        
        playerLimit[msg.sender].totalLimit += buySize.mul(1e18).mul(limitPerAcre[tokenName]);
        

    }
    
    function decreaseUsedLimit(address account,uint256 amount) internal {
        require(  amount <= playerLimit[account].usedLimit );
        
        playerLimit[account].usedLimit -= amount;
    }
    
    function increaseUsedLimit(address account,uint256 amount) internal {
        require( amount <= ( playerLimit[account].totalLimit.sub( playerLimit[account].usedLimit)) );
        playerLimit[account].usedLimit += amount;
    }
    
    function getTotalLimit(address account) public view returns(uint256){
        return playerLimit[account].totalLimit ;
    }
    
    function getUsedLimit(address account) public view returns(uint256){
        return playerLimit[account].usedLimit ;
    }
    
    function getAvailableLimit(address account) public view returns(uint256){
        return getTotalLimit(account) - getUsedLimit(account);
    }
    
    function isPlayer(address account) public view returns(bool){
        return ((playerLimit[account].totalLimit > 0) || (playerLimit[account].usedLimit > 0) );
    }
   
    function playerStake(address account, uint256 amount) internal {
        increaseUsedLimit(account,amount);
    } 
    
    function playerWithdraw(address account, uint256 amount)  internal {
        decreaseUsedLimit(account,amount);
    }
   
}

contract hfERC20Pool is PlayerStation ,LPTokenWrapper, IRewardDistributionRecipient {
    using SafeMath for uint8;
    //support token
    IERC20 public supportToken = IERC20(0x3c91B301f80cCB055e97d2405523C95e72892D30);
    uint256 public DURATION = 86400; // 
    uint256 public settlement_DURATION = 300;//5 min

    uint256 public starttime = 1622649600; // 2021/6/3 0:0:0 (UTC UTC +08:00)
    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;

    uint256 public rewardNow;
    uint256 public rewardNext;
    bool public canNext = false;
    uint256 public DURATION_NEXT;
    uint256 public settlement_DURATION_NEXT;
    uint256 public lastUpadteNotifyTime = 0;


    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;
    
    uint256 public farmerRewards;
    uint256 public noOneWateringRewards;
    
    mapping(address => uint256) public allRewards;
    
    uint8 public farmerType;
    uint8 public farmerUsed;
    uint8 public farmerSize;
    
    address public controller;
    address public farmer;
    

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount,uint256 supply);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(string opType, address indexed user, uint256 reward);
    event Rescue(address indexed dst, uint sad);
    event RescueToken(address indexed dst, address indexed token, uint sad);
    event SnapShot(address indexed user, uint256 amount);
    event SetNextRewardInfo(address indexed user, bool can, uint256 reward, uint256 DURATION_NEW, uint256 settlement_DURATION_NEW);
    event notifyRewardAmounted(uint256 reward,uint256 new_DURATION,uint256 new_settlement_DURATION);
    event doSettlemented(address account,address watering,uint256 farmerEarn,uint256 playerEarn,uint256 wateringEarn);
    event beFarmered(address newFarmer);
    event bePlayered(string tokenName,address playeradr,uint8 buySize,uint256 amount,uint8 farmerUsed,uint256 supply);
    event farmerGetRewarded(address farmer, uint256 trueReward);
    event playerGetRewarded(address farmer, uint256 trueReward);


    constructor() public{
        tokenAddr = IERC20(0x3F55e5ce0B746aD862b232d848a47a9dC4d75858);
        initPool();
    }
    
   //function initPool(uint256 _starttime,address oper,address controller,uint8 farmerTypesml) internal {
   function initPool() internal {
        rewardDistribution = _msgSender();
        starttime = 1630682392;
        farmerType = 3;
        farmerSize = super.getFarmerPoolSize(farmerType,tokenAddr.symbol());
        super.setOper(0xfBb4EB0A18920dc242761Fb3417663ba25784c22);
        controller = 0xA519964c924bBd2e25698C46BBb59D9d2646d3bc;
   }
   
    modifier onlyController(){
        require(msg.sender == controller);
        _;
    }
    
    modifier onlyFarmer(){
        require(msg.sender == farmer);
        _;
    }


    modifier canFarmering(){
        require(farmer != address(0));
        _;
    }

    modifier checkStart() {
        require(block.timestamp >= starttime, "not start");
        _;
    }
    
    modifier onlyPlayer(address account) {
        require(super.isPlayer(account));
        _;
    }

    modifier canBuy() {
        require(farmerSize > farmerUsed);
        _;
    }

    modifier updateReward(address account) {
        bool _next = canNext;
        if (_next && rewardNext == rewardNow && DURATION == DURATION_NEXT) {
            doContinue(false);
            _next = false;
        }
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        if (_next){
            doContinue(true);
        }
        _;
    }
    
    modifier checkDoSettlement() {
        require((block.timestamp>=(starttime + DURATION - settlement_DURATION )) && (block.timestamp <= (periodFinish)));
        _;
    }
    
    function  getStartTime() public view returns(uint256){
        return starttime;
    }
    
    function setController(address newController) public onlyOwner{
        controller = newController;
    }
    /**
    function setFarmer(address newFarmer) public onlyOwner{
        farmer = newFarmer;
    }    
    **/
    function getFarmerUsed() public view returns(uint8){
        return farmerUsed;
    }
    
    
    function getFarmerType() public view returns(uint8){
        return farmerType;
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, (periodFinish - settlement_DURATION ));
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalSupply() == 0) {
            return rewardPerTokenStored;
        }
        return
        rewardPerTokenStored.add(
            lastTimeRewardApplicable()
            .sub(lastUpdateTime)
            .mul(rewardRate)
            .mul(1e18)
            .div(totalSupply())
        );
    }
    
    function doSettlement(address account,address watering) onlyOper checkDoSettlement updateReward(account) public{
        
        require(earned(account) > 0);
        
        //rewardPerTokenStored = rewardPerToken();
        
        uint256 farmerEarn   = earned(account).mul(20).div(100);
        uint256 playerEarn   = earned(account).mul(75).div(100);
        uint256 wateringEarn = earned(account).mul(5).div(100);
        
        allRewards[account] += playerEarn;
        farmerRewards       += farmerEarn;
        
        //userRewardPerTokenPaid[account] = rewardPerTokenStored;
        
        if(watering != address(0)){
            supportToken.transfer(watering,wateringEarn);
        }
        else{
            noOneWateringRewards += wateringEarn;
        }
        
        rewards[account] = 0;
        
        emit doSettlemented(account,watering,farmerEarn,playerEarn,wateringEarn);
        
    }
    
    function checkNoOneWateringRewards() public view returns(uint256){
        return noOneWateringRewards;
    }
    
    function beFarmer(address newFarmer)  onlyController external {
        
        farmer = newFarmer;
        emit beFarmered(newFarmer);
    }
    
    function bePlayer(uint8 buySize , uint256 amount) public canFarmering canBuy checkStart  {
        string memory tokenName = IERC20(tokenAddr).symbol(); 
        
        require(farmerSize >= (farmerUsed.add(buySize)));
        
        super.bePlayer(tokenName ,   buySize ,  amount);
        
        farmerUsed += buySize;
        
        supportToken.transferFrom(msg.sender,farmer,amount);
        
        emit bePlayered(tokenName,msg.sender,buySize,amount,farmerUsed,super.totalSupply());
    }
    
    function playerEarned(address account) public view returns(uint256){
        return allRewards[account];
    }

    function earned(address account)  internal view returns (uint256) {
        return
        balanceOf(account)
        .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
        .div(1e18)
        .add(rewards[account]);
    }

    // stake visibility is public as overriding LPTokenWrapper's stake() function
    function stake(uint256 amount) public updateReward(msg.sender) onlyPlayer(msg.sender)  checkStart {
        require(amount > 0, "Cannot stake 0");
        super.playerStake(msg.sender,amount);
        super.stake(amount);
        emit Staked(msg.sender, amount ,super.totalSupply());
        emit SnapShot(msg.sender, balanceOf(msg.sender));
    }

    function withdraw(uint256 amount) public updateReward(msg.sender) onlyPlayer(msg.sender) checkStart {
        require(amount > 0, "Cannot withdraw 0");
        super.playerWithdraw(msg.sender,amount);
        super.withdraw(amount);
        emit Withdrawn(msg.sender, amount);
        emit SnapShot(msg.sender, balanceOf(msg.sender));
    }
    
    function emergencyWithdraw() public onlyPlayer(msg.sender){
        //require(amount > 0, "Cannot withdraw 0");
        
        uint256 amount = super.getUsedLimit(msg.sender);
        
        super.playerWithdraw(msg.sender,amount);
        super.withdraw(amount);
        emit Withdrawn(msg.sender, amount);
        emit SnapShot(msg.sender, balanceOf(msg.sender));
    }

    function playerWithdrawAndGetReward(uint256 amount) public updateReward(msg.sender) checkStart {
        require(amount <= balanceOf(msg.sender), "Cannot withdraw exceed the balance");
        withdraw(amount);
        playerGetReward();
    }

    function playerExit() external {
        withdraw(balanceOf(msg.sender));
        playerGetReward();
    }

    function farmerGetReward() public updateReward(msg.sender) onlyFarmer() checkStart {
        uint256 trueReward = farmerRewards;
        if (trueReward > 0) {
            //rewards[msg.sender] = 0;
            farmerRewards    = 0;
            supportToken.safeTransfer(msg.sender, trueReward);
            emit farmerGetRewarded(msg.sender, trueReward);
        }
    }

    function playerGetReward() public updateReward(msg.sender) onlyPlayer(msg.sender) checkStart {
        uint256 trueReward = allRewards[msg.sender];
        if (trueReward > 0) {
            //rewards[msg.sender] = 0;
            allRewards[msg.sender] = 0;
            supportToken.safeTransfer(msg.sender, trueReward);
            emit playerGetRewarded(msg.sender, trueReward);
        }
    }

    function getReward() internal updateReward(msg.sender) checkStart {
        uint256 trueReward = earned(msg.sender);
        if (trueReward > 0) {
            rewards[msg.sender] = 0;
            supportToken.safeTransfer(msg.sender, trueReward);
            emit RewardPaid("old method",msg.sender, trueReward);
        }
    }

    function doContinue(bool changed) internal{
        if (block.timestamp > periodFinish && DURATION_NEXT > 0 && settlement_DURATION_NEXT >0) {
            rewardRate = rewardNext.div(DURATION_NEXT - settlement_DURATION_NEXT);
            lastUpdateTime = changed ? block.timestamp : periodFinish;
            periodFinish = lastUpdateTime.add(DURATION_NEXT);
            rewardNow = rewardNext;
            DURATION =DURATION_NEXT;
            emit RewardAdded(rewardNext);
         }
    }

    function setNextRewardInfo(bool can, uint256 reward, uint256 DURATION_NEW ,uint256 new_settlement_DURATION)
    external
    onlyRewardDistribution
    {
        canNext = can;
        rewardNext = reward;
        DURATION_NEXT = DURATION_NEW;
        settlement_DURATION_NEXT = new_settlement_DURATION;
        //settlement_DURATION_NEXT = new_settlement_DURATION;
        emit SetNextRewardInfo(msg.sender,can,reward,DURATION_NEW,new_settlement_DURATION);
    }

   function notifyRewardAmount(uint256 reward,uint256 new_DURATION,uint256 new_settlement_DURATION)
   external
   onlyRewardDistribution
   updateReward(address(0))
    {
        require(block.timestamp.sub(lastUpadteNotifyTime) > 900, "cannot trigger twice in 15 min");
        require(new_DURATION > 0);
        require(new_DURATION > new_settlement_DURATION);
        lastUpadteNotifyTime = block.timestamp;
        rewardNow = reward;
        rewardNext = reward;
        DURATION = new_DURATION;
        DURATION_NEXT = new_DURATION;
        settlement_DURATION = new_settlement_DURATION;
        settlement_DURATION_NEXT = new_settlement_DURATION;

        if (block.timestamp > starttime) {
            if (block.timestamp >= periodFinish) {
                rewardRate = reward.div(DURATION - settlement_DURATION);
            } else {
                uint256 remaining = (periodFinish- settlement_DURATION).sub(block.timestamp);
                uint256 leftover = remaining.mul(rewardRate);
                rewardRate = reward.add(leftover).div(DURATION - settlement_DURATION);
            }
            lastUpdateTime = block.timestamp;
            periodFinish = block.timestamp.add(DURATION);
            emit RewardAdded(reward);
        } else {
            rewardRate = reward.div(DURATION - settlement_DURATION);
            lastUpdateTime = starttime;
            periodFinish = starttime.add(DURATION);
            emit RewardAdded(reward);
        }
        emit notifyRewardAmounted( reward, new_DURATION, new_settlement_DURATION);
    }

    /**
     * @dev rescue simple transfered unrelated token.
     */
    function rescue(address to_, IERC20 token_, uint256 amount_)
    external
    onlyOwner
    {
        require(to_ != address(0), "must not 0");
        require(amount_ > 0, "must gt 0");
        require(token_ != supportToken, "must not hfToken");
        require(token_ != tokenAddr, "must not this stakeToken");

        token_.transfer(to_, amount_);
        emit RescueToken(to_, address(token_), amount_);
    }

    /**
     **/
     /**
    function setRewardRate(uint256 newRewardRate) public onlyRewardDistribution  updateReward(address(0)){
        require(newRewardRate < rewardRate);
        rewardRate = newRewardRate;
    }
    **/
}