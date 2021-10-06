/**
 *Submitted for verification at BscScan.com on 2021-10-05
*/

pragma solidity ^0.6.0;

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
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}
pragma solidity ^0.6.2;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

pragma solidity ^0.6.0;

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


pragma solidity ^0.6.0;



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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
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
pragma solidity ^0.6.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
contract ReentrancyGuard {
    bool private _notEntered;

    constructor () internal {
        // Storing an initial non-zero value makes deployment a bit more
        // expensive, but in exchange the refund on every call to nonReentrant
        // will be lower in amount. Since refunds are capped to a percetange of
        // the total transaction's gas, it is best to keep them low in cases
        // like this one, to increase the likelihood of the full refund coming
        // into effect.
        _notEntered = true;
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
        require(_notEntered, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _notEntered = false;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _notEntered = true;
    }
}
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
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }

    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
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
}
pragma solidity ^0.6.0;



/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}
// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;

interface IStakePool {

    function tierCount() external view returns (uint8);

    function poolInfo(uint pid)
    external view returns (
        uint unitAmount,
        uint allocPoint,
        uint lockDuration,
        uint totalSupply
    );
    function balanceOf(address user) external view  returns (uint);
    
    function totalAllocPoint() external view returns (uint);

    function allocPointsOf(address _sender)  external view returns(uint); 
    function allocPercentageOf(address _sender)  external view returns(uint); 
    
}
contract PresaleTest is ReentrancyGuard, Ownable, Pausable {

// libraries

    // ReentrancyGuard helps prevent reentrant calls to a function.
    // Inheriting from ReentrancyGuard will make the nonReentrant modifier available, which can be applied to functions to make sure there are no nested (reentrant) calls to them.
    // Note that because there is a single nonReentrant guard, functions marked as nonReentrant may not call one another. This can be worked around by making those functions private, and then adding external nonReentrant entry points to them.

    // Ownable provides a basic access control mechanism, where there is an account (an owner) that can be granted exclusive access to specific functions.
    // By default, the owner account will be the one that deploys the contract. This can later be changed with transferOwnership.
    // This module is used through inheritance. It will make available the modifier onlyOwner, which can be applied to your functions to restrict their use to the owner.

    // Pausable is an emergency stop mechanism that can be triggered by an authorized account.
    // This module is used through inheritance. It will make available the modifiers whenNotPaused and whenPaused, which can be applied to the functions of your contract. 
    // Note that they will not be pausable by simply including this module, only once the modifiers are put in place.
    
    // IERC20 Interface of the ERC20 standard as defined in the EIP. Does not include the optional functions; to access them see ERC20Detailed.
    // totalSupply()
    // balanceOf(account)
    // transfer(recipient, amount)
    // allowance(owner, spender)
    // approve(spender, amount)
    // transferFrom(sender, recipient, amount)

    // SafeERC20 wraps around ERC20 operations that throw on failure (when the token contract returns false). 
    // Tokens that return no value (and instead revert or throw on failure) are also supported, non-reverting calls are assumed to be successful. 
    using SafeERC20 for IERC20;

    // SafeMath provides mathematical functions that protect your contract from overflows and underflows.
    // Include the contract with using SafeMath for uint256; and then call the functions:
    // myNumber.add(otherNumber)    myNumber.sub(otherNumber)   myNumber.div(otherNumber)
    // myNumber.mul(otherNumber)    myNumber.mod(otherNumber)
    using SafeMath for uint256;

    // EnumerableMap: like  mapping type, but with key-value enumeration: 
    // informs how many entries a mapping has, and iterate over them (which is not possible with mapping).
    // EnumerableSet: like EnumerableMap, but for sets. Can be used to store privileged accounts, issued IDs, etc.


// modifiers

    modifier whenNotStarted {
        require(block.timestamp < startTime, "presale has already started");
        _;
    }

    modifier onProgress {
        require(block.timestamp < endTime && block.timestamp >= startTime, "presale not in progress");
        _;
    }

    modifier whenFinished {
        require(block.timestamp > endTime, "presale is not finished");
        _;
    }

    modifier whenNotFinished {
        require(block.timestamp <= endTime, "presale is finished");
        _;
    }
  
    modifier whiteListed {
        require(whiteList[msg.sender] == true || msg.sender == owner(), "not whiteListed");
        _;
    }

   modifier claimDisabled {
        require(claimEnabled == false , "Claiming may not be started!");
        _;
    }

// variables

    // participants

    // rate = wantToken per investToken
    uint public rate; 

    // supply of wantToken
    uint public supply;

    // redundant?
    address private keeper;

    // calling parameters
    IERC20 public wantToken;
    IERC20 public investToken;
    uint public startTime;
    uint public endTime;
    uint public hardCap;
    uint public softCap;
    IStakePool public stakePool;

    // investToken absolutes
    struct Allocation {
        address adres;
        uint allocated;     
        uint swapped;       
    }

    // wantTopken absolutes
    // claims also designed for vesting
    struct Claim {
        uint amount;        // absolute wantToken
        uint unlockTime; // for releasing the claim 
        bool isSwapped;       // absolute wantToken
    }

    // maps + array to controll the process   
    mapping(address=> uint) public allocations;     // absolute amount of allocated investToken per user
    mapping(address=> uint) public swaps;           // absolute amount of swapped investToken per user
    
    mapping(address => mapping(uint256 => Claim)) claims;      // records of claims wantToken per user per vesting 
    //  example:
    //  claims[<address>][1] = 
    //      {   amount:12.14, 
    //          unlockTime:123312213, s
    //          claimed: false
    //      }

    address[] public userAdresses;  // array of users holding allocation

    // maps to support the process
    mapping(address => bool) whiteList;
    // mapping(address => bool) blackList;

    // counter to measure traffic 
    uint256 counter;

    // control buttons for the admimn
    bool claimEnabled;  // set by owner, turns off/on claim process
    bool swapEnabled;   // set by owner, turns off/on swap process

    // sale
    uint public availTokens;  // total available wantToken

    // totalizer to follow the process by admin / frontEnd
    uint public allocateTotal;  // absolute total allocated investToken
    uint public swapTotal;      // absolute total swapped investToken
    uint public pendingTotal;   // absolute total swapped wantToken 
    uint public claimTotal;     // absolute total claimed wantToken


// events
    event Deposited(address indexed user, uint amount);
    event Swapped(address indexed user, uint amount);
    event Claimed(address indexed user, uint amount);


// constructor
    constructor ( address _wantToken, address _investToken, uint _startTime, uint _duration, uint _hardCap, uint _softCap, address _stakePool
    ) public {
        
        require(_hardCap > _softCap, "invalid caps");
        require(_duration > 0, "invalid duration");

        wantToken = IERC20(_wantToken);
        investToken = IERC20(_investToken);
        startTime = _startTime;
        endTime = _startTime.add(_duration);
        hardCap = _hardCap;
        softCap = _softCap;
        stakePool = IStakePool(_stakePool);

        whiteList[msg.sender] = true;
        claimEnabled = false;
        swapEnabled = false;

        availTokens =0;

        allocateTotal=0;
        swapTotal=0;
        pendingTotal;
        claimTotal=0;  

        counter = 0 ;
    }


// core routines                                           
    function depositTokens(uint _amount) external onlyOwner whenNotStarted claimDisabled{     //{ : note : disabled for test.. enable before live
        // do some checks 
        require(wantToken.balanceOf(msg.sender) >= _amount, "!amount");
        require(_amount >= 100, "min amount is 100 tokens");

        // transfer x amount of wantToken to presale
        wantToken.safeTransferFrom(msg.sender, address(this), _amount);

        availTokens = _amount;

        // set supply 
        emit Deposited(msg.sender, _amount);
    }

    function userConnect() external onProgress claimDisabled {
        counter++;
        // check if user is not blacklisted ! ==> map whitelist
        // check if user is in the system !  ==>  is not in (map allocations)

        // check if this is a new user
       if  (_checkOrAddUser(msg.sender)){
            // this is a new user
            uint _perc = getAllocPercentage(msg.sender);
            // if user has tier ::: if the user has allocPercentage()
            if (_perc > 0) {
                 // allocation is percentage of hardcap

                uint _allocate = (hardCap * _perc) / (10**3) ; // remains another / (10**3 ).. this is for the frontEnd..?
                // fill record in map allocations
                allocations[msg.sender] = _allocate ;
                swaps[msg.sender] = 0 ;

                allocateTotal += _allocate;
            }
       }
    }


    function swap(uint _amount) external onProgress claimDisabled {
        // do some checks 
        require(allocations[msg.sender] >= _amount, "!no allocation");
        // require (WBNB is correct token)
      //  require(address(investToken) != investToken, "should use the proper  investToken");


        // transfer tokens to this stakePool
        investToken.transferFrom(msg.sender, address(this), _amount);

        // sum swaps
        swaps[msg.sender] += _amount; 

        // deduct allocation
        allocations[msg.sender] -= _amount; 

        // sum totalizer swapTotal
        swapTotal += _amount; 

        // do not deduct totalizer allocateTotal
        //  allocateTotal -= amount;

        // do some other things
        //  !! 

        emit Swapped(msg.sender, _amount);
    }


    function createClaims()  external whenFinished onlyOwner claimDisabled {
        // do some checks 
        require(!claimEnabled, "claims are already enabled!");

        // check swapp
        uint _claimStart = startTime + 10800;    // set start time of first claim 

        // optional vesting !
        // uint _initialPercentage = 100; // set start initial percentage
        // uint _numberOfVests = 1; // set number of vest

        uint _userClaim;
        uint _swapped; 
        Claim memory _claim;

        // for each userAdresses
       for(uint _i = 0 ; _i < userAdresses.length ; _i++) {

            // retrieve swapped investToken
            _swapped = swaps[userAdresses[_i]]; 

            // calculate number of wantToken
            _userClaim =(_swapped / hardCap ) * availTokens; 

            // define the Claim struct {amount, unlockTime, swapped}
            _claim = Claim(_userClaim, _claimStart, false);

            // write claims map
            claims[userAdresses[_i]][0] = _claim;
        }
        claimEnabled = true;
    }


    function createVestingClaims() external whenFinished onlyOwner claimDisabled {
        // do some checks 
        require(!claimEnabled, "claims are already enabled!");

        // check swapp
        uint _claimStart = startTime + 10800;    // set start time of first claim 
        uint _initialPercentage = 50; // set start initial percentage
            
        uint _numberOfVests = 6; // set number of vest
        uint _vestPause = (86400 * 28);     // set vesting periods to 4 weeks

        uint _swapped; 
        uint _userClaim;
        uint  _thisQty;
        uint  _thisTime;
        Claim memory _claim;

        // for each userAdresses
       for(uint _i = 0 ; _i < userAdresses.length ; _i++) {

            // retrieve swapped investToken
            _swapped = swaps[userAdresses[_i]]; 

            // calculate number of wantToken
            _userClaim = (_swapped / hardCap ) * availTokens; 

            // set the variables for initial claim
            _thisQty = (_userClaim * (100 - _initialPercentage)) / 100 ;
            _thisTime = _claimStart;

            /*  
            struct Claim {
                    uint amount;        // absolute wantToken
                    uint256 unlockTime; // for releasing the claim 
                    bool isSwapped;       // absolute wantToken
                }
            */

            // define the Claim struct {amount, unlockTime, isSwapped}
            _claim = Claim(_thisQty, _thisTime, false);

            // write claims map
            claims[userAdresses[_i]][0]= _claim;

            // iterate over remaining claims
            // calculate tokens per step
            uint _stepPercentage = (100 - _initialPercentage) / (_numberOfVests - 1) ; 
            _thisQty = (_userClaim * _stepPercentage) / 100 ; 

            for(uint _j = 1 ; _j < _numberOfVests ; _j++) {
                _thisTime += _vestPause;
                _claim = Claim(_thisQty, _thisTime, false);
                claims[userAdresses[_i]][_j]= _claim;
            }

        }
        claimEnabled = true;
    }

    function swapClaim(uint _vestNumber) external whenFinished {
        // do some checks 
       require( claims[msg.sender][_vestNumber].isSwapped == false, 'this claim is already swapped!');
        uint _amount = claims[msg.sender][_vestNumber].amount ;

        // transfer tokens to this stakePool
        wantToken.safeTransfer(msg.sender, _amount/1000);

        // sum totalizer
        swapTotal+= _amount;

        // set this claim to isSwapped
        claims[msg.sender][_vestNumber].isSwapped = true;

        // do some other things
        //  !! 
        emit Claimed(msg.sender, _amount);
    }

//  subroutines
    function _checkOrAddUser(address _user) internal returns (bool) {
        bool _new = true;
        for(uint i = 0 ; i < userAdresses.length ; i++) {
            if (userAdresses[i] == _user) {
                _new = false;
                i = userAdresses.length ;
            }
        }
        if (_new){
            userAdresses.push(_user);
        }
        return _new;
    }

// getters 
    function getUserAllocated() view public returns (uint) {
        // retrieve absolute amount of allocated investToken for this user;
       return allocations[msg.sender];
    }

    function getUserSwapped() view public returns (uint) {
        // retrieve absolute amount of allocated investToken for this user;
       return swaps[msg.sender];
    }

    function getUserClaim(uint16 _vestNr) view public returns (uint) {
        // retrieve absolute amount of allocated investToken for this user;
       return claims[msg.sender][_vestNr].amount;
    }

    function getUserClaimFlag(uint16 _vestNr) view public returns (bool) {
        // retrieve absolute amount of allocated investToken for this user;
       return claims[msg.sender][_vestNr].isSwapped;
    }

    function getTotalAllocPoint() view public returns (uint) {
        // retrieve totalAllocPoint() from StakePool.sol
       return stakePool.totalAllocPoint();
    }

    function getAllocPoint(address _sender) view public returns (uint) {
        // retrieve allocPoint() from StakePool.sol
       return stakePool.allocPointsOf(_sender);
    }

    function getAllocPercentage(address _sender) view public returns (uint) {
        // retrieve allocPercentage() from StakePool.sol
       return stakePool.allocPercentageOf(_sender);
    }


// setters
    function setEnableSwap(bool _flag) external onlyOwner onProgress {
        // do some checks 
        swapEnabled = _flag;
    }

    function setEnableClaim(bool _flag) external onlyOwner onProgress {
        // do some checks 
        claimEnabled = _flag;
    }

    function setStartTime(uint _startTime, uint _duration) external onlyOwner {
        startTime = _startTime;
        endTime = _startTime.add(_duration);
    }


    function setHardCap(uint _cap) external onlyOwner whenNotStarted {
        require(_cap > softCap, "invalid soft cap");
        hardCap = _cap;
    }

    function setSoftCap(uint _cap) external onlyOwner whenNotStarted {
        require(_cap < hardCap, "invalid soft cap");
        softCap = _cap;
    }

}