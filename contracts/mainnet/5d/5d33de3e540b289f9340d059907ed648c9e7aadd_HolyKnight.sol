// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;


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
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
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

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
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
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


// Interface to represent a contract in pools that requires additional
// deposit and withdraw of LP tokens. One of the examples at the time of writing
// is Yearn vault, which takes yCRV which is already LP token and returns yyCRV 
interface Stakeable {
    function deposit(uint) external;
    function withdraw(uint) external;
}

/**
 * @dev A token holder contract that will allow a beneficiary to extract the
 * tokens after a given release time.
 *
 * Useful for simple vesting schedules like "advisors get all of their tokens
 * after 1 year".
 */
contract TokenTimelock {
    using SafeERC20 for IERC20;

    // ERC20 basic token contract being held
    IERC20 private _token;

    // beneficiary of tokens after they are released
    address private _beneficiary;

    // timestamp when token release is enabled
    uint256 private _releaseTime;

    constructor (IERC20 token, address beneficiary, uint256 releaseTime) public {
        // solhint-disable-next-line not-rely-on-time
        require(releaseTime > block.timestamp, "TokenTimelock: release time is before current time");
        _token = token;
        _beneficiary = beneficiary;
        _releaseTime = releaseTime;
    }

    /**
     * @return the token being held.
     */
    function token() public view returns (IERC20) {
        return _token;
    }

    /**
     * @return the beneficiary of the tokens.
     */
    function beneficiary() public view returns (address) {
        return _beneficiary;
    }

    /**
     * @return the time when the tokens are released.
     */
    function releaseTime() public view returns (uint256) {
        return _releaseTime;
    }

    /**
     * @notice Transfers tokens held by timelock to beneficiary.
     */
    function release() public virtual {
        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp >= _releaseTime, "TokenTimelock: current time is before release time");

        uint256 amount = _token.balanceOf(address(this));
        require(amount > 0, "TokenTimelock: no tokens to release");

        _token.safeTransfer(_beneficiary, amount);
    }
}

contract HolderTimelock is TokenTimelock {
  constructor(
    IERC20 _token, 
    address _beneficiary,
    uint256 _releaseTime
  )
    public
    TokenTimelock(_token, _beneficiary, _releaseTime)
  //solhint-disable-next-line
  {}
}

/**
 * @dev A token holder contract that will allow a beneficiary to extract the
 * tokens by portions based on a metric (TVL)
 *
 * This is ported from openzeppelin-ethereum-package
 *
 * Currently the holder contract is Ownable (while the owner is current beneficiary)
 * still, this allows to check the method calls in blockchain to verify fair play.
 * In the future it will be possible to use automated calculation, e.g. using
 * https://github.com/ConcourseOpen/DeFi-Pulse-Adapters TVL calculation, then
 * ownership would be transferred to the managing contract.
 */
contract HolderTVLLock is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 private constant RELEASE_PERCENT = 2;
    uint256 private constant RELEASE_INTERVAL = 1 weeks;

    // ERC20 basic token contract being held
    IERC20 private _token;

    // beneficiary of tokens after they are released
    address private _beneficiary;

    // timestamp when token release was made last time
    uint256 private _lastReleaseTime;

    // timestamp of first possible release time
    uint256 private _firstReleaseTime;

    // TVL metric for last release time
    uint256 private _lastReleaseTVL;

    // amount that already was released
    uint256 private _released;

    event TVLReleasePerformed(uint256 newTVL);

    constructor (IERC20 token, address beneficiary, uint256 firstReleaseTime) public {
        //as contract is deployed by Holyheld token, transfer ownership to dev
        transferOwnership(beneficiary);

        // solhint-disable-next-line not-rely-on-time
        require(firstReleaseTime > block.timestamp, "release time before current time");
        _token = token;
        _beneficiary = beneficiary;
        _firstReleaseTime = firstReleaseTime;
    }

    /**
     * @return the token being held.
     */
    function token() public view returns (IERC20) {
        return _token;
    }

    /**
     * @return the beneficiary of the tokens.
     */
    function beneficiary() public view returns (address) {
        return _beneficiary;
    }

    /**
     * @return the time when the tokens were released last time.
     */
    function lastReleaseTime() public view returns (uint256) {
        return _lastReleaseTime;
    }

    /**
     * @return the TVL marked when the tokens were released last time.
     */
    function lastReleaseTVL() public view returns (uint256) {
        return _lastReleaseTVL;
    }

    /**
     * @notice Transfers tokens held by timelock to beneficiary.
     * only owner can call this method as it will write new TVL metric value
     * into the holder contract
     */
    function release(uint256 _newTVL) public onlyOwner {
        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp >= _firstReleaseTime, "current time before release time");
        require(block.timestamp > _lastReleaseTime + RELEASE_INTERVAL, "release interval is not passed");
        require(_newTVL > _lastReleaseTVL, "only release if TVL is higher");

        // calculate amount that is possible to release
        uint256 balance = _token.balanceOf(address(this));
        uint256 totalBalance = balance.add(_released);

        uint256 amount = totalBalance.mul(RELEASE_PERCENT).div(100);
        require(balance > amount, "available balance depleted");

        _token.safeTransfer(_beneficiary, amount);
	    _lastReleaseTime = block.timestamp;
	    _lastReleaseTVL = _newTVL;
	    _released = _released.add(amount);

        emit TVLReleasePerformed(_newTVL);
    }
}

/**
 * @title TokenVesting
 * @dev A token holder contract that can release its token balance gradually like a
 * typical vesting scheme, with a cliff and vesting period. Optionally revocable by the
 * owner.
 */
contract HolderVesting is Ownable {
    // The vesting schedule is time-based (i.e. using block timestamps as opposed to e.g. block numbers), and is
    // therefore sensitive to timestamp manipulation (which is something miners can do, to a certain degree). Therefore,
    // it is recommended to avoid using short time durations (less than a minute). Typical vesting schemes, with a
    // cliff period of a year and a duration of four years, are safe to use.
    // solhint-disable not-rely-on-time

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 private constant RELEASE_INTERVAL = 1 weeks;

    event TokensReleased(address token, uint256 amount);
    event TokenVestingRevoked(address token);

    // beneficiary of tokens after they are released
    address private _beneficiary;

    // ERC20 basic token contract being held
    IERC20 private _token;

    // Durations and timestamps are expressed in UNIX time, the same units as block.timestamp.
    uint256 private _start;
    uint256 private _duration;

    // timestamp when token release was made last time
    uint256 private _lastReleaseTime;

    bool private _revocable;

    uint256 private _released;
    bool private _revoked;

    /**
     * @dev Creates a vesting contract that vests its balance of any ERC20 token to the
     * beneficiary, gradually in a linear fashion until start + duration. By then all
     * of the balance will have vested.
     * @param beneficiary address of the beneficiary to whom vested tokens are transferred
     * @param start the time (as Unix time) at which point vesting starts
     * @param duration duration in seconds of the period in which the tokens will vest
     * @param revocable whether the vesting is revocable or not
     */
    constructor(IERC20 token, address beneficiary, uint256 start, uint256 duration, bool revocable) public {

        require(beneficiary != address(0), "beneficiary is zero address");
        require(duration > 0, "duration is 0");
        // solhint-disable-next-line max-line-length
        require(start.add(duration) > block.timestamp, "final time before current time");

        _token = token;
        
        _beneficiary = beneficiary;
        //as contract is deployed by Holyheld token, transfer ownership to dev
        transferOwnership(beneficiary);

        _revocable = revocable;
        _duration = duration;
        _start = start;
    }

    /**
     * @return the beneficiary of the tokens.
     */
    function beneficiary() public view returns (address) {
        return _beneficiary;
    }

    /**
     * @return the start time of the token vesting.
     */
    function start() public view returns (uint256) {
        return _start;
    }

    /**
     * @return the duration of the token vesting.
     */
    function duration() public view returns (uint256) {
        return _duration;
    }

    /**
     * @return true if the vesting is revocable.
     */
    function revocable() public view returns (bool) {
        return _revocable;
    }

    /**
     * @return the amount of the token released.
     */
    function released() public view returns (uint256) {
        return _released;
    }

    /**
     * @return true if the token is revoked.
     */
    function revoked() public view returns (bool) {
        return _revoked;
    }

    /**
     * @return the time when the tokens were released last time.
     */
    function lastReleaseTime() public view returns (uint256) {
        return _lastReleaseTime;
    }

    /**
     * @notice Transfers vested tokens to beneficiary.
     */
    function release() public {
        uint256 unreleased = _releasableAmount();

        require(unreleased > 0, "no tokens are due");
        require(block.timestamp > _lastReleaseTime + RELEASE_INTERVAL, "release interval is not passed");

        _released = _released.add(unreleased);

        _token.safeTransfer(_beneficiary, unreleased);
        _lastReleaseTime = block.timestamp;

        emit TokensReleased(address(_token), unreleased);
    }

    /**
     * @notice Allows the owner to revoke the vesting. Tokens already vested
     * remain in the contract, the rest are returned to the owner.
     */
    function revoke() public onlyOwner {
        require(_revocable, "cannot revoke");
        require(!_revoked, "vesting already revoked");

        uint256 balance = _token.balanceOf(address(this));

        uint256 unreleased = _releasableAmount();
        uint256 refund = balance.sub(unreleased);

        _revoked = true;

        _token.safeTransfer(owner(), refund);

        emit TokenVestingRevoked(address(_token));
    }

    /**
     * @dev Calculates the amount that has already vested but hasn't been released yet.
     */
    function _releasableAmount() private view returns (uint256) {
        return _vestedAmount().sub(_released);
    }

    /**
     * @dev Calculates the amount that has already vested.
     */
    function _vestedAmount() private view returns (uint256) {
        uint256 currentBalance = _token.balanceOf(address(this));
        uint256 totalBalance = currentBalance.add(_released);

        if (block.timestamp < _start) {
            return 0;
        } else if (block.timestamp >= _start.add(_duration) || _revoked) {
            return totalBalance;
        } else {
            return totalBalance.mul(block.timestamp.sub(_start)).div(_duration);
        }
    }
}

/**
 * @dev // HolyKnight is using LP to distribute Holyheld token
 *
 * it does not mint any HOLY tokens, they must be present on the
 * contract's token balance. Balance is not intended to be refillable.
 *
 * Note that it's ownable and the owner wields tremendous power. The ownership
 * will be transferred to a governance smart contract once HOLY is sufficiently
 * distributed and the community can show to govern itself.
 *
 * Have fun reading it. Hopefully it's bug-free. God bless.
 */
contract HolyKnight is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user
    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of HOLYs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accHolyPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accHolyPerShare` (and `lastRewardCalcBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
        // Thus every change in pool or allocation will result in recalculation of values
        // (otherwise distribution remains constant btwn blocks and will be properly calculated)
        uint256 stakedLPAmount;
    }

    // Info of each pool
    struct PoolInfo {
        IERC20 lpToken;              // Address of LP token contract
        uint256 allocPoint;          // How many allocation points assigned to this pool. HOLYs to distribute per block
        uint256 lastRewardCalcBlock; // Last block number for which HOLYs distribution is already calculated for the pool
        uint256 accHolyPerShare;     // Accumulated HOLYs per share, times 1e12. See below
        bool    stakeable;         // we should call deposit method on the LP tokens provided (used for e.g. vault staking)
        address stakeableContract;     // location where to deposit LP tokens if pool is stakeable
        IERC20  stakedHoldableToken;
    }

    // The Holyheld token
    HolyToken public holytoken;
    // Dev address
    address public devaddr;
    // Treasury address
    address public treasuryaddr;

    // The block number when HOLY mining starts
    uint256 public startBlock;
    // The block number when HOLY mining targeted to end (if full allocation).
    // used only for token distribution calculation, this is not a hard limit
    uint256 public targetEndBlock;

    // Total amount of tokens to distribute
    uint256 public totalSupply;
    // Reserved percent of HOLY tokens for current distribution (e.g. when pool allocation is intentionally not full)
    uint256 public reservedPercent;
    // HOLY tokens created per block, calculatable through updateHolyPerBlock()
    // updated once in the constructor and owner calling setReserve (if needed)
    uint256 public holyPerBlock;

    // Info of each pool
    PoolInfo[] public poolInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools
    uint256 public totalAllocPoint = 0;
    
    // Info of each user that stakes LP tokens
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    // Info of total amount of staked LP tokens by all users
    mapping (address => uint256) public totalStaked;



    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event Treasury(address indexed token, address treasury, uint256 amount);

    constructor(
        HolyToken _token,
        address _devaddr,
        address _treasuryaddr,
        uint256 _totalsupply,
        uint256 _reservedPercent,
        uint256 _startBlock,
        uint256 _targetEndBlock
    ) public {
        holytoken = _token;

        devaddr = _devaddr;
        treasuryaddr = _treasuryaddr;

        // as knight is deployed by Holyheld token, transfer ownership to dev
        transferOwnership(_devaddr);

        totalSupply = _totalsupply;
        reservedPercent = _reservedPercent;

        startBlock = _startBlock;
        targetEndBlock = _targetEndBlock;

        // calculate initial token number per block
        updateHolyPerBlock();
    }

    // Reserve some percentage of HOLY token distribution
    // (e.g. initially, 10% of tokens are reserved for future pools to be added)
    function setReserve(uint256 _reservedPercent) public onlyOwner {
        reservedPercent = _reservedPercent;
        updateHolyPerBlock();
    }

    function updateHolyPerBlock() internal {
        // safemath substraction cannot overflow
        holyPerBlock = totalSupply.sub(totalSupply.mul(reservedPercent).div(100)).div(targetEndBlock.sub(startBlock));
        massUpdatePools();
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(uint256 _allocPoint, IERC20 _lpToken, bool _stakeable, address _stakeableContract, IERC20 _stakedHoldableToken, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardCalcBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            allocPoint: _allocPoint,
            lastRewardCalcBlock: lastRewardCalcBlock,
            accHolyPerShare: 0,
            stakeable: _stakeable,
            stakeableContract: _stakeableContract,
            stakedHoldableToken: IERC20(_stakedHoldableToken)
        }));

        if(_stakeable)
        {
            _lpToken.approve(_stakeableContract, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        }
    }

    // Update the given pool's HOLY allocation point. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    // View function to see pending HOLYs on frontend.
    function pendingHoly(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accHolyPerShare = pool.accHolyPerShare;
        uint256 lpSupply = totalStaked[address(pool.lpToken)];
        if (block.number > pool.lastRewardCalcBlock && lpSupply != 0) {
            uint256 multiplier = block.number.sub(pool.lastRewardCalcBlock);
            uint256 tokenReward = multiplier.mul(holyPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accHolyPerShare = accHolyPerShare.add(tokenReward.mul(1e12).div(lpSupply));
        }
        return user.amount.mul(accHolyPerShare).div(1e12).sub(user.rewardDebt);
    }

    // Update reward vairables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date when lpSupply changes
    // For every deposit/withdraw/harvest pool recalculates accumulated token value
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardCalcBlock) {
            return;
        }
        uint256 lpSupply = totalStaked[address(pool.lpToken)];
        if (lpSupply == 0) {
            pool.lastRewardCalcBlock = block.number;
            return;
        }
        uint256 multiplier = block.number.sub(pool.lastRewardCalcBlock);
        uint256 tokenRewardAccumulated = multiplier.mul(holyPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        // no minting is required, the contract already has token balance pre-allocated
        // accumulated HOLY per share is stored multiplied by 10^12 to allow small 'fractional' values
        pool.accHolyPerShare = pool.accHolyPerShare.add(tokenRewardAccumulated.mul(1e12).div(lpSupply));
        pool.lastRewardCalcBlock = block.number;
    }

    // Deposit LP tokens to HolyKnight for HOLY allocation.
    function deposit(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accHolyPerShare).div(1e12).sub(user.rewardDebt);
            if(pending > 0) {
                safeTokenTransfer(msg.sender, pending); //pay the earned tokens when user deposits
            }
        }
        // this condition would save some gas on harvest calls
        if (_amount > 0) {
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            user.amount = user.amount.add(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accHolyPerShare).div(1e12);

        totalStaked[address(pool.lpToken)] = totalStaked[address(pool.lpToken)].add(_amount);
        if (pool.stakeable) {
            uint256 prevbalance = pool.stakedHoldableToken.balanceOf(address(this));
            Stakeable(pool.stakeableContract).deposit(_amount);
            uint256 balancetoadd = pool.stakedHoldableToken.balanceOf(address(this)).sub(prevbalance);
            user.stakedLPAmount = user.stakedLPAmount.add(balancetoadd);
            // protect received tokens from moving to treasury
            totalStaked[address(pool.stakedHoldableToken)] = totalStaked[address(pool.stakedHoldableToken)].add(balancetoadd);
        }

        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from HolyKnight.
    function withdraw(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);

        uint256 pending = user.amount.mul(pool.accHolyPerShare).div(1e12).sub(user.rewardDebt);
        safeTokenTransfer(msg.sender, pending);
        
        if (pool.stakeable) {
            // reclaim back original LP tokens and withdraw all of them, regardless of amount
            Stakeable(pool.stakeableContract).withdraw(user.stakedLPAmount);
            totalStaked[address(pool.stakedHoldableToken)] = totalStaked[address(pool.stakedHoldableToken)].sub(user.stakedLPAmount);
            user.stakedLPAmount = 0;
            // even if returned amount is less (fees, etc.), return all that is available
            // (can be impacting treasury rewards if abused, but is not viable due to gas costs
            // and treasury yields can be claimed periodically)
            uint256 balance = pool.lpToken.balanceOf(address(this));
            if (user.amount < balance) {
                pool.lpToken.safeTransfer(address(msg.sender), user.amount);
            } else {
                pool.lpToken.safeTransfer(address(msg.sender), balance);
            }
            totalStaked[address(pool.lpToken)] = totalStaked[address(pool.lpToken)].sub(user.amount);
            user.amount = 0;
            user.rewardDebt = 0;
        } else {
            require(user.amount >= _amount, "withdraw: not good");
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
            totalStaked[address(pool.lpToken)] = totalStaked[address(pool.lpToken)].sub(_amount);
            user.amount = user.amount.sub(_amount);
            user.rewardDebt = user.amount.mul(pool.accHolyPerShare).div(1e12);
        }
        
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        if (pool.stakeable) {
            // reclaim back original LP tokens and withdraw all of them, regardless of amount
            Stakeable(pool.stakeableContract).withdraw(user.stakedLPAmount);
            totalStaked[address(pool.stakedHoldableToken)] = totalStaked[address(pool.stakedHoldableToken)].sub(user.stakedLPAmount);
            user.stakedLPAmount = 0;
            uint256 balance = pool.lpToken.balanceOf(address(this));
            if (user.amount < balance) {
                pool.lpToken.safeTransfer(address(msg.sender), user.amount);
            } else {
                pool.lpToken.safeTransfer(address(msg.sender), balance);
            }
        } else {
            pool.lpToken.safeTransfer(address(msg.sender), user.amount);    
        }

        totalStaked[address(pool.lpToken)] = totalStaked[address(pool.lpToken)].sub(user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
    }

    // Safe holyheld token transfer function, just in case if rounding error causes pool to not have enough HOLYs.
    function safeTokenTransfer(address _to, uint256 _amount) internal {
        uint256 balance = holytoken.balanceOf(address(this));
        if (_amount > balance) {
            holytoken.transfer(_to, balance);
        } else {
            holytoken.transfer(_to, _amount);
        }
    }

    // Update dev address by the previous dev.
    function dev(address _devaddr) public {
        require(msg.sender == devaddr, "forbidden");
        devaddr = _devaddr;
    }

    // Update treasury address by the previous treasury.
    function treasury(address _treasuryaddr) public {
        require(msg.sender == treasuryaddr, "forbidden");
        treasuryaddr = _treasuryaddr;
    }

    // Send yield on an LP token to the treasury
    // have just address (and not pid) as agrument to be able to recover
    // tokens that could be directly transferred and not present in pools
    function putToTreasury(address _token) public onlyOwner {
        uint256 availablebalance = getAvailableBalance(_token);
        require(availablebalance > 0, "not enough tokens");
        putToTreasuryAmount(_token, availablebalance);
    }

    // Send yield amount realized from holding LP tokens to the treasury
    function putToTreasuryAmount(address _token, uint256 _amount) public onlyOwner {
        require(_token != address(holytoken), "cannot transfer holy tokens");
        uint256 availablebalance = getAvailableBalance(_token);
        require(_amount <= availablebalance, "not enough tokens");
        IERC20(_token).safeTransfer(treasuryaddr, _amount);
        emit Treasury(_token, treasuryaddr, _amount);
    }

    // Get available token balance that can be put to treasury
    // For pools with internal staking, all lpToken balance is contract's
    // (bacause user tokens are converted to pool.stakedHoldableToken when depositing)
    // HOLY tokens themselves and user lpTokens are protected by this check
    function getAvailableBalance(address _token) internal view returns (uint256) {
        uint256 availablebalance = IERC20(_token).balanceOf(address(this)) - totalStaked[_token];
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            PoolInfo storage pool = poolInfo[pid]; //storage pointer used read-only
            if (pool.stakeable && address(pool.lpToken) == _token)
            {
                availablebalance = IERC20(_token).balanceOf(address(this));
                break;
            }
        }
        return availablebalance;
    }
}

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

/**
 * @dev // Holyheld token is a ERC20 token for Holyheld.
 *
 * total amount is fixed at 100M HOLY tokens.
 * HOLY token does not have mint functions.
 * It will allocate upon creation the initial transfers
 * of tokens. It is not ownable or having any other
 * means of distribution other than transfers in its constructor. 
 */
// HolyToken. Ownable, fixed-amount (non-mintable) with governance to be added
contract HolyToken is ERC20("Holyheld", "HOLY") {

    // main developers (founders) multi-sig wallet
    // 1 mln tokens
    address public founder;

    // Treasury
    // accumulates LP yield
    address public treasury;

    // weekly vested supply, reclaimable by 2% in a week by founder (WeeklyVested contract)
    // 9 mln
    address public timeVestedSupply;

    // TVL-growth vested supply, reclaimable by 2% in a week if TVL is a new ATH (TVLVested contract)
    // 10 mln
    address public growthVestedSupply;

    // main supply, locked for 4 months (TimeVested contract)
    // 56 mln
    address public mainSupply;
    
    // Pool supply (ruled by HolyKnight contract)
    // 24 mln
    address public poolSupply;

    uint public constant AMOUNT_INITLIQUIDITY = 1000000 * 1e18;
    uint public constant AMOUNT_OPERATIONS = 9000000 * 1e18;
    uint public constant AMOUNT_TEAM = 10000000 * 1e18;
    uint public constant DISTRIBUTION_SUPPLY = 24000000 * 1e18;
    uint public constant DISTRIBUTION_RESERVE_PERCENT = 20;
    uint public constant MAIN_SUPPLY = 56000000 * 1e18;

    uint public constant MAIN_SUPPLY_VESTING_PERIOD = 127 days;
    uint public constant VESTING_START = 1602115200; //8 Oct 2020
    uint public constant VESTING_START_GROWTH = 1604188800; //1 Nov 2020

    // parameters for HolyKnight construction
    uint public constant START_LP_BLOCK = 10950946;
    // used for tokens per block calculation to distribute in about 4 months
    uint public constant END_LP_BLOCK = 11669960;

    // Constructor code is only run when the contract
    // is created
    constructor(address _founder, address _treasuryaddr) public {
        founder = _founder;	  //address that deployed contract becomes initial founder
        treasury = _treasuryaddr; //treasury address is created beforehand

        // Timelock contract will hold main supply for 4 months till Jan 2021
	    mainSupply = address(new HolderTimelock(this, founder, block.timestamp + MAIN_SUPPLY_VESTING_PERIOD));

        // TVL metric based vesting
	    growthVestedSupply = address(new HolderTVLLock(this, founder, VESTING_START_GROWTH));

        // Standard continuous vesting contract
	    timeVestedSupply = address(new HolderVesting(this, founder, VESTING_START, 365 days, false));

        // HOLY token distribution though liquidity mining
	    poolSupply = address(new HolyKnight(this, founder, treasury, DISTRIBUTION_SUPPLY, DISTRIBUTION_RESERVE_PERCENT, START_LP_BLOCK, END_LP_BLOCK));

        //allocate tokens to addresses upon creation, no further minting possible
	    _mint(founder, AMOUNT_INITLIQUIDITY);
	    _mint(timeVestedSupply, AMOUNT_OPERATIONS);
	    _mint(growthVestedSupply, AMOUNT_TEAM);
	    _mint(poolSupply, DISTRIBUTION_SUPPLY);
	    _mint(mainSupply, MAIN_SUPPLY); 
    }
}