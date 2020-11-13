// File: @openzeppelin/contracts/utils/ReentrancyGuard.sol
// SPDX-License-Identifier: MIT
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

// File: @openzeppelin/contracts/GSN/Context.sol

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol

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
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: @openzeppelin/contracts/utils/Address.sol

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

// File: @openzeppelin/contracts/math/SafeMath.sol

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

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

// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol

pragma solidity ^0.6.0;




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

// File: browser/SPO/LPTokenWrapper.sol

pragma solidity ^0.6.0;

/**
 * @title  lpTokenWrapper
 * @author Synthetix (forked from /Synthetixio/synthetix/contracts/StakingRewards.sol)
 *         Audit: https://github.com/sigp/public-audits/blob/master/synthetix/unipool/review.pdf
 *         Changes by: SPO.
 * @notice LP Token wrapper to facilitate tracking of staked balances
 * @dev    Changes:
 *          - Added UserData and _historyTotalSupply to track history balances
 *          - Changing 'stake' and 'withdraw' to internal funcs
 */
contract LPTokenWrapper is ReentrancyGuard {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public lpToken;

    uint256 private _totalSupply;
    mapping (uint256 => uint256) private _historyTotalSupply;
    mapping(address => uint256) private _balances;
    //Hold in seconds before withdrawal after last time staked
    uint256 public holdTime;
    
    struct UserData {
        //Period when balance becomes nonzero or last period rewards claimed
        uint256 period;
        //Last time deposited. used to implement holdDays
        uint256 lastTime;
        mapping (uint256 => uint) historyBalance;
    }

    mapping (address => UserData) private userData;

    /**
     * @dev TokenWrapper constructor
     * @param _lpToken Wrapped token to be staked
     * @param _holdDays Hold days after last deposit
     */
    constructor(address _lpToken, uint256 _holdDays) internal {
        lpToken = IERC20(_lpToken);
        holdTime = _holdDays.mul(1 days);
    }

    /**
     * @dev Get the total amount of the staked token
     * @return uint256 total supply
     */
    function totalSupply()
        public
        view
        returns (uint256)
    {
        return _totalSupply;
    }

    /**
     * @dev Get the total amount of the staked token
     * @param _period Period for which total supply returned
     * @return uint256 total supply
     */
    function historyTotalSupply(uint256 _period)
        public
        view
        returns (uint256)
    {
        return _historyTotalSupply[_period];
    }

    /**
     * @dev Get the balance of a given account
     * @param _address User for which to retrieve balance
     */
    function balanceOf(address _address)
        public
        view
        returns (uint256)
    {
        return _balances[_address];
    }

    /**
     * @dev Deposits a given amount of lpToken from sender
     * @param _amount Units of lpToken
     */
    function _stake(uint256 _amount, uint256 _period)
        internal
        nonReentrant
    {

        _totalSupply = _totalSupply.add(_amount);
        _updateHistoryTotalSupply(_period);
        UserData storage user = userData[msg.sender]; 
        if(_balances[msg.sender] == 0) user.period = _period;
        _balances[msg.sender] = _balances[msg.sender].add(_amount);
        user.historyBalance[_period] = _balances[msg.sender];
        user.lastTime = block.timestamp;
        lpToken.safeTransferFrom(msg.sender, address(this), _amount);
    }

    /**
     * @dev Withdraws a given stake from sender
     * @param _amount Units of lpToken
     */
    function _withdraw(uint256 _amount, uint256 _period)
        internal
        nonReentrant
    {
        //Check first if user has sufficient balance, added due to hold requrement 
        //("Cannot withdraw, tokens on hold" will be fired even if user  has no balance)
        require(_balances[msg.sender] >= _amount, "Not enough balance");
        UserData storage user = userData[msg.sender]; 
        require(block.timestamp.sub(user.lastTime) >= holdTime, "Cannot withdraw, tokens on hold");
        _totalSupply = _totalSupply.sub(_amount);
        _updateHistoryTotalSupply(_period);
        _balances[msg.sender] = _balances[msg.sender].sub(_amount);
        user.historyBalance[_period] = _balances[msg.sender];
        lpToken.safeTransfer(msg.sender, _amount);
    }
    
    /**
     * @dev Updates history total supply
     * @param _period Current period
     */
     function _updateHistoryTotalSupply(uint256 _period)
        internal
    {
        _historyTotalSupply[_period] = _totalSupply;
    }
    
    /**
     * @dev Returns User Data
     * @param _address address of the User
     */
     function getUserData(address _address)
        internal
        view
        returns (UserData storage)
    {
        return userData[_address];
    }

    /**
     * @dev Sets user's period and balance for that period
     * @param _address address of the User
     */
     function _updateUser(address _address, uint256 _period)
        internal
    {
        userData[_address].period = _period;
        userData[_address].historyBalance[_period] = _balances[_address];
    }   

}

// File: browser/SPO/StakingPool.sol

pragma solidity ^0.6.0;

contract StakingPool is Ownable, ReentrancyGuard, LPTokenWrapper {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;
    
    //interface for Rewards Token
    IERC20 public rewardsToken;
    //Conctact status states
    enum Status {Setup, Running, Ended}
    
    //Constants
    uint256 constant public CALC_PRECISION = 1e18;

    // Address where fees will be sent if fee isn't 0
    address public feeBeneficiary;
    // Fee in PPM (Parts Per Million), can be 0
    uint256 public fee;
    //Status of contract
    Status public status;
    //Rewards for period
    uint256 public rewardsPerPeriodCap;
    //Total rewards for all periods
    uint256 public rewardsTotalCap;
    //Staking Period in seconds
    uint256 public periodTime;
    //Total Periods
    uint256 public totalPeriods;
    //Grace Periods Time (time window after contract is Ended when users have to claim their Reward Tokens)
    //after this period ends, no reward withdrawal is possible and contact owner can withdraw unclamed Reward Tokens
    uint256 public gracePeriodTime;
    //Time when contracts starts
    uint256 public startTime;
    //Time when contract ends 
    uint256 public endTime;
    //Time when contract closes (endTime + gracePeriodTime)
    uint256 public closeTime;
    
    
    //Last Period
    uint256 public period;
    
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event WithdrawnERC20(address indexed user, address token, uint256 amount);
    

    /** @dev Updates Period before executing function */
    modifier updatePeriod() {
        _updatePeriod();
        _;
    }
    
    /** @dev Make sure setup is finished */
    modifier onlyAfterSetup() {
        require(status != Status.Setup, "Setup is not finished");
        _;
    }

    /** @dev Make sure setup is finished */
    modifier onlyAfterStart() {
        require(startTime != 0, "Staking is not started");
        _;
    }

    /**
     * @dev Contract constructor
     * @param _lpToken Contract address of LP Token
     * @param _rewardsToken Contract address of Rewards Token
     * @param _rewardsPerPeriodCap Amount of tokens to be distributed each period (1e18)
     * @param _periodDays Period time in days
     * @param _totalPeriods Total periods contract will be running
     * @param _gracePeriodDays Grace period in days 
     * @param _holdDays Time in days LP Tokens will be on hold for user after each stake
     * @param _feeBeneficiary Address where fees will be sent
     * @param _fee Fee in ppm
     */
    constructor(
        address _lpToken,
        address _rewardsToken,
        uint256 _rewardsPerPeriodCap,
        uint256 _periodDays, 
        uint256 _totalPeriods,
        uint256 _gracePeriodDays,
        uint256 _holdDays,
        address _feeBeneficiary,
        uint256 _fee
    )
        public
        LPTokenWrapper(_lpToken, _holdDays)
    {
        require(_lpToken.isContract(), "LP Token address must be a contract");
        require(_rewardsToken.isContract(), "Rewards Token address must be a contract");
        rewardsToken = IERC20(_rewardsToken);
        rewardsPerPeriodCap = _rewardsPerPeriodCap;
        rewardsTotalCap = _rewardsPerPeriodCap.mul(_totalPeriods);
        periodTime = _periodDays.mul(1 days);
        totalPeriods = _totalPeriods;
        gracePeriodTime = _gracePeriodDays.mul(1 days);
        feeBeneficiary = _feeBeneficiary;
        fee = _fee;
    }

    /***************************************
                    ADMIN
    ****************************************/

    /**
     * @dev Updates contract setup and mark contract status as Running if all requirements are met
     * @param _now Start contract immediatly if true
     */    
    function adminStart(bool _now) 
        external 
        onlyOwner
    {
        require(status == Status.Setup, "Already started");
        require(rewardsToken.balanceOf(address(this)) >= rewardsTotalCap, "Not enough reward tokens to start");
        status = Status.Running;
        if(_now) _startNow();
    }
    
    /**
     * @dev Option to start contract even there is no deposits yet
     */
    function adminStartNow()
        external
        onlyOwner
        onlyAfterSetup
    {
        require(startTime == 0 && status == Status.Running, "Already started");
        _startNow();
        
    }
    
    /**
     * @dev Option to end contract 
     */
    function adminEnd()
        external
        onlyOwner
        onlyAfterSetup
    {
        require(block.timestamp >= endTime && endTime != 0, "Cannot End");
        _updatePeriod();
    }
    
    /**
     * @dev Close contract after End and Grace period and withdraw unclamed rewards tokens
     * @param _address where to send
     */
     function adminClose(address _address)
        external
        onlyOwner
        onlyAfterSetup
    {
        require(block.timestamp >= closeTime && closeTime != 0, "Cannot Close");
        uint256 _rewardsBalance = rewardsToken.balanceOf(address(this));
        if(_rewardsBalance > 0) rewardsToken.safeTransfer(_address, _rewardsBalance);
    }
    
    /**
     * @dev Withdraw other than LP or Rewards tokens 
     * @param _tokenAddress address of the token contract to withdraw
     */
     function adminWithdrawERC20(address _tokenAddress)
        external
        onlyOwner
    {
        require(_tokenAddress != address(rewardsToken) && _tokenAddress != address(lpToken), "Cannot withdraw Reward or LP Tokens");
        IERC20 _token = IERC20(_tokenAddress);
        uint256 _balance = _token.balanceOf(address(this));
        require(_balance != 0, "Not enough balance");
        uint256 _fee = _balance.mul(fee).div(1e6);
        if(_fee != 0){
            _token.safeTransfer(feeBeneficiary, _fee);
            emit WithdrawnERC20(feeBeneficiary, _tokenAddress, _fee);
        }
        _token.safeTransfer(msg.sender, _balance.sub(_fee));
        emit WithdrawnERC20(msg.sender, _tokenAddress, _balance.sub(_fee));
    }
    
    /***************************************
                    PRIVATE
    ****************************************/
    
    /**
     * @dev Starts the contract
     */
    function _startNow()
        private
    {
        startTime = block.timestamp;
        endTime = startTime.add(periodTime.mul(totalPeriods));  
        closeTime = endTime.add(gracePeriodTime);
    }

    /**
     * @dev Updates last period to current and set status to Ended if needed
     */
    function _updatePeriod()
        private
    {
        uint256 _currentPeriod = currentPeriod();
        if(_currentPeriod != period){
            period = _currentPeriod;
            _updateHistoryTotalSupply(period);
            if(_currentPeriod == totalPeriods){
                status = Status.Ended;
                //release hold of LP tokens
                holdTime = 0;
            }
        }
    }
    
 
    /***************************************
                    ACTIONS
    ****************************************/
    
    /**
     * @dev Stakes an amount for the sender, assumes sender approved allowace at LP Token contract _amount for this contract address
     * @param _amount of LP Tokens
     */
    function stake(uint256 _amount)
        external
        onlyAfterSetup
        updatePeriod
    {
        require(_amount > 0, "Cannot stake 0");
        require(status != Status.Ended, "Contract is Ended");
        if(startTime == 0) _startNow();
        _stake(_amount, period);
        emit Staked(msg.sender, _amount);
    }

    /**
     * @dev Withdraws given LP Token stake amount from the pool
     * @param _amount LP Tokens to withdraw
     */
    function withdraw(uint256 _amount)
        public
        onlyAfterStart
        updatePeriod
    {
        require(_amount > 0, "Cannot withdraw 0");
        _withdraw(_amount, period);
        emit Withdrawn(msg.sender, _amount);
    }
    
    /**
     * @dev Claims outstanding rewards for the sender.
     * First updates outstanding reward allocation and then transfers.
     */
    function claimReward()
        public
        nonReentrant
        onlyAfterStart
        updatePeriod
    {
        require(block.timestamp <= closeTime, "Contract is Closed");
        uint256 reward = calculateReward(msg.sender);
        if (reward > 0) {
            _updateUser(msg.sender, period);
            rewardsToken.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }    
    
    /**
     * @dev Withdraws LP Tokens stake from pool and claims any rewards
     */
    function exit() 
        external
    {
        uint256 _amount = balanceOf(msg.sender);
        if(_amount !=0) withdraw(_amount);
        claimReward();
    }
    
    /***************************************
                    GETTERS
    ****************************************/

    /**
     * @dev Calculates current period, if contract is ended returns currentPeriod + 1 (totalPeriods)
     */
    function currentPeriod() 
        public 
        view 
        returns (uint256)
    {
        uint256 _currentPeriod;
        if(startTime != 0 && endTime != 0)
        {
            if(block.timestamp >= endTime){
                _currentPeriod = totalPeriods;
            }else{
                _currentPeriod = block.timestamp.sub(startTime).div(periodTime);
            }
        }
        return _currentPeriod;
    }

    /**
     * @dev Calculates pending rewards for the user since last period claimed rewards to current period
     * @param _address address of the user
     */
     function calculateReward(address _address) 
        public
        view
        returns (uint256)
    {
        UserData storage user = getUserData(_address);
        if(block.timestamp >= closeTime) return 0;
        uint256 _period = currentPeriod();
        uint256 periodTotalSupply;
        uint256 savedTotalSupply;
        uint256 periodBalance;
        uint256 savedBalance;
        uint256 rewardTotal;
        if(_period > user.period){
            savedTotalSupply =  historyTotalSupply(user.period);
            savedBalance = user.historyBalance[user.period];
            if(savedTotalSupply != 0){
                rewardTotal = rewardTotal.add(
                    rewardsPerPeriodCap.mul(
                        savedBalance
                    ).mul(
                        CALC_PRECISION
                    ).div(
                        savedTotalSupply
                    ).div(
                        CALC_PRECISION
                    )
                );
            }
            for(uint256 i = user.period+1; i < _period; i++){
                periodTotalSupply = historyTotalSupply(i);
                periodBalance = user.historyBalance[i];
                periodBalance == 0 ? periodBalance = savedBalance : savedBalance = periodBalance;
                periodTotalSupply == 0 ? periodTotalSupply = savedTotalSupply : savedTotalSupply = periodTotalSupply;
                if(periodTotalSupply != 0){
                    rewardTotal = rewardTotal.add(
                        rewardsPerPeriodCap.mul(
                            periodBalance
                        ).mul(
                            CALC_PRECISION
                        ).div(
                            periodTotalSupply
                        ).div(
                            CALC_PRECISION
                        )
                    );
                }
            }
        }
        return rewardTotal;
    }

    /**
     * @dev Returns estimated current period reward for the user based on current total supply and his balance
     * @param _address address of the user
     */
     function estimateReward(address _address) 
        public
        view
        returns (uint256)
    {
        uint256 _totalSupply = totalSupply();
        if(_totalSupply == 0 || block.timestamp >= closeTime) return 0;
        return rewardsPerPeriodCap.mul(
            balanceOf(_address)
        ).mul(
            CALC_PRECISION
        ).div(
            _totalSupply
        ).div(
            CALC_PRECISION
        );
    }

}