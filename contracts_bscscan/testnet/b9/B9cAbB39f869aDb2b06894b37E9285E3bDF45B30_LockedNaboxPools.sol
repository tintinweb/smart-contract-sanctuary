/**
 *Submitted for verification at BscScan.com on 2021-12-07
*/

// SPDX-License-Identifier: MIT

/**
 *Submitted for verification at Etherscan.io on 2020-09-03
*/

pragma solidity ^0.6.12;

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



// Part: ReentrancyGuard

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
abstract contract ReentrancyGuard {
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
 * @title Various utilities useful for uint256.
 */
library UInt256Lib {

    uint256 private constant MAX_INT256 = ~(uint256(1) << 255);

    /**
     * @dev Safely converts a uint256 to an int256.
     */
    function toInt256Safe(uint256 a)
    internal
    pure
    returns (int256)
    {
        require(a <= MAX_INT256);
        return int256(a);
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
 

contract LockedNaboxPools is Ownable,ReentrancyGuard {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct Queue {
        uint128 start;
        uint128 end;
        mapping(uint128 => LockedRewardInfo) items;
    }

    function enqueue(Queue storage queue, LockedRewardInfo memory item) internal {
        queue.items[queue.end++] = item;
    }

    // function removeFirst(Queue storage queue) internal {
    //     delete queue.items[queue.start++];
    // }

    // Info of each user.
    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        Queue lockedRewardQueue;
        uint256 lockedReward; // 锁定的未领取总金额
    }

    struct LockedRewardInfo {
        uint256 amount;       // 奖励数量
        uint256 unlockNumber; // 解锁高度
    }

    // Info of each pool.
    struct PoolInfo {
        uint16 lockDays;                 // reward locked days
        uint256 dayBlockCount;           // The number of blocks generated per day
        uint256 totalBlockCount;         // The total number of blocks generated during lock time
        IERC20 lpToken;    
        IERC20 candyToken; 
        uint256 startBlock; 
        uint256 lastRewardBlock;  // Last block number that token distribution occurs.
        uint256 accPerShare;      // Accumulated token per share, times 1e12. See below.
        uint256 candyPerBlock; 
        uint256 lpSupply;
        uint256 candyBalance;
    }

    // Info of each pool.
    PoolInfo[] public poolInfo;
    
    // Info of each user that stakes LP tokens.
    mapping (uint256 => mapping (address => UserInfo)) userInfo; 
 
    event AddPool(address indexed user, address lpToken, address candyToken, uint16 lockDays, uint256 candyBalance);
    event UpdateStartBlock(address indexed user, uint256 indexed pid, uint256 startBlock);
    event AddCandy(address indexed user, uint256 indexed pid, uint256 candyAmount, bool withUpdate);
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

    // Add a new lp to the pool. Can only be called by the owner in the before starting, or the controller can call after starting.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    // _lockDays 矿池奖励锁定的天数，赋值0视为不锁定
    function add(uint16 _lockDays, uint256 _minuteBlockCount, IERC20 _lpToken, IERC20 _candyToken, uint256 _candyPerBlock, uint256 _amount, uint256 _startBlock, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > _startBlock ? block.number : _startBlock;
        require(_amount > 0, "add: amount not good");

        uint256 _dayBlockCount = 0;
        uint256 _totalBlockCount = 0;
        if(_lockDays > 0) {
           _dayBlockCount = _minuteBlockCount ;                //锁定1天的区块数量
           _totalBlockCount = _minuteBlockCount * _lockDays;  //锁定天数内的总区块数量
        }

        poolInfo.push(PoolInfo({
            lockDays: _lockDays,
            dayBlockCount: _dayBlockCount,
            totalBlockCount: _totalBlockCount,
            lpToken: _lpToken,
            candyToken: _candyToken,
            candyPerBlock: _candyPerBlock,
            startBlock: _startBlock,
            lastRewardBlock: lastRewardBlock,
            candyBalance: _amount,
            accPerShare: 0,
            lpSupply: 0
        }));

        emit AddPool(msg.sender, address(_lpToken), address(_candyToken), _lockDays, _amount);
    }

    function updateStartBlock(uint256 _pid,uint256 _startBlock) public onlyOwner {
        require(_pid < poolInfo.length, "invalid pool id");
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.startBlock) {
            uint256 lastRewardBlock = block.number > _startBlock ? block.number : _startBlock;
            pool.startBlock = _startBlock;
            pool.lastRewardBlock = lastRewardBlock;
        }
        emit UpdateStartBlock(msg.sender, _pid, _startBlock);
    }
    
    function addCandy(uint256 _pid, uint256 _amount, bool _withUpdate) public onlyOwner {
        require(_pid < poolInfo.length, "invalid pool id");
        if (_withUpdate) {
            massUpdatePools();
        }
        PoolInfo storage pool = poolInfo[_pid];
        pool.candyBalance = pool.candyBalance.add(_amount);
        emit AddCandy(msg.sender, _pid, _amount, _withUpdate);
    }
    
    // View function to see pending token on frontend.
    function pendingToken(uint256 _pid, address _user) external view returns (uint256) {
        require(_pid < poolInfo.length, "invalid pool id");
        UserInfo memory user = userInfo[_pid][_user];
        uint256 _pendingReward =  calcPendingReward(_pid, _user);
        return _pendingReward.add(user.lockedReward);
    }

    function pendingReward(uint256 _pid, address _user) external view returns (uint256) {
        require(_pid < poolInfo.length, "invalid pool id");
        uint256 _pendingReward =  calcPendingReward(_pid, _user);
        return _pendingReward;
    }

    // View function to see pending reward on frontend.
    function calcPendingReward(uint256 _pid, address _user) internal view returns (uint256) {
        PoolInfo memory pool = poolInfo[_pid];
        UserInfo memory user = userInfo[_pid][_user];

        uint256 lpSupply = pool.lpSupply;
        uint256 accPerShare = pool.accPerShare;
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 reward = (block.number.sub(pool.lastRewardBlock)).mul(pool.candyPerBlock);
            accPerShare = accPerShare.add(reward.mul(1e12).div(lpSupply));   // 此处乘以1e12，在下面会除以1e12
        }
        uint256 _pendingReward = user.amount.mul(accPerShare).div(1e12).sub(user.rewardDebt);
        if (_pendingReward == 0) {
            return 0;
        }
        //池子里合约账户上实际余额
        uint256 realBalance = pool.candyToken.balanceOf(address(this));

        if (_pendingReward >= realBalance && pool.candyBalance >= realBalance) {
            return realBalance;
        } else if(_pendingReward >= pool.candyBalance && realBalance >= pool.candyBalance){
            return pool.candyBalance;
        }
   
        return _pendingReward;
    }

    // Update reward vairables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    function updatePool(uint256 _pid) public {
        require(_pid < poolInfo.length, "invalid pool id");
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        
        uint256 lpSupply = pool.lpSupply;
        
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        
        uint256 reward = (block.number.sub(pool.lastRewardBlock)).mul(pool.candyPerBlock);
        pool.accPerShare = pool.accPerShare.add(reward.mul(1e12).div(lpSupply)); 
        pool.lastRewardBlock = block.number;
    }

    function deposit(uint256 _pid, uint256 _amount) public {
        require(_pid < poolInfo.length, "invalid pool id");
        _deposit(_pid, _amount);
    }

    function depositDesc(uint256 _pid, uint256 _amount) public {
        require(_pid < poolInfo.length, "invalid pool id");
        _deposit(_pid, _amount);
    }

    function _deposit(uint256 _pid, uint256 _amount) internal {
        require(_pid < poolInfo.length, "invalid pool id");
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        _receive(pool, user);
        if (_amount > 0) {
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
        }
        user.amount = user.amount.add(_amount);
        pool.lpSupply = pool.lpSupply.add(_amount);
        user.rewardDebt = user.amount.mul(pool.accPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from pool.
    function withdraw(uint256 _pid, uint256 _amount) public {
        require(_pid < poolInfo.length, "invalid pool id");
        _withdraw(_pid, _amount);
    }

    function withdrawDesc(uint256 _pid, uint256 _amount) public {
        require(_pid < poolInfo.length, "invalid pool id");
        _withdraw(_pid, _amount);
    }

    function _withdraw(uint256 _pid, uint256 _amount) internal {
        require(_pid < poolInfo.length, "invalid pool id");
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        _receive(pool, user);
        user.amount = user.amount.sub(_amount);
        pool.lpSupply = pool.lpSupply.sub(_amount);
        user.rewardDebt = user.amount.mul(pool.accPerShare).div(1e12);
        if (_amount > 0) {
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) external nonReentrant {
        require(_pid < poolInfo.length, "invalid pool id");
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        pool.lpToken.safeTransfer(address(msg.sender), user.amount);
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
        pool.lpSupply = pool.lpSupply.sub(user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
        // 清空锁定队列
        user.lockedRewardQueue.start = user.lockedRewardQueue.end;
        user.lockedReward = 0;
    }
 
    function safeTokenTransfer(IERC20 _token, address _to, uint256 _amount,uint256 _poolBalance) internal returns (uint256) {
        if (_amount == 0) {
            return 0;
        }
        uint256 transferAmount = _amount;
        uint256 bal = _token.balanceOf(address(this)); 
        if (transferAmount >= bal && _poolBalance >= bal) {
            transferAmount = bal;
        } else if(transferAmount >= _poolBalance && bal >= _poolBalance){
            transferAmount = _poolBalance;
        }
        if (transferAmount == 0) {
            return 0;
        }
        _token.safeTransfer(_to, transferAmount);
        return transferAmount;
    }

    // 计算用户总锁定数量、计算用户已解锁数量、已解锁的直接转账给用户，添加用户当前的锁定奖励
    function _receive(PoolInfo storage pool, UserInfo storage user) internal {
        //pool.lockDays 为0时，没有锁定
        if(pool.lockDays == 0) {
            // 添加用户当前的锁定奖励
            uint256 pending = user.amount.mul(pool.accPerShare).div(1e12).sub(user.rewardDebt);
            if(pending > 0) {
                uint256 realTransfer = safeTokenTransfer(pool.candyToken, msg.sender, pending, pool.candyBalance);
                pool.candyBalance = pool.candyBalance.sub(realTransfer);
            }
        }else {
            _receiveWithLockPool(pool, user);
        }
        
    }

    //锁定的池子获取奖励
    function _receiveWithLockPool(PoolInfo storage pool, UserInfo storage user) internal {
        // 计算用户已解锁的数量
        uint256 unlockReward = 0;
        uint128 deleteHeaderLength = 0;
        uint256 currentNumber = block.number;
        

        Queue storage queue = user.lockedRewardQueue;
        uint length = queue.end - queue.start;
        if (length > 0) {
            // 当最近添加的锁定已解锁，说明所有锁定都已解锁
            if (queue.items[queue.end - 1].unlockNumber <= currentNumber) {
                unlockReward = user.lockedReward;
                // 清空锁定队列
                user.lockedRewardQueue.start = user.lockedRewardQueue.end;
            } else {
                // 正序遍历的方式计算领取
                LockedRewardInfo memory info;
                for (uint128 i = queue.start; i < queue.end; i++) {
                    info = queue.items[i];
                    if (info.unlockNumber > currentNumber) {
                        // 计算需要删除的头部长度
                        deleteHeaderLength = i - queue.start;
                        break;
                    } 
                    unlockReward = unlockReward.add(info.amount);
                }
            }
        
            // 已解锁的直接转账给用户
            if (unlockReward > 0) {
                uint256 realTransfer = safeTokenTransfer(pool.candyToken, msg.sender, unlockReward, pool.candyBalance);
                pool.candyBalance = pool.candyBalance.sub(realTransfer);
                // 更新用户锁定数量
                user.lockedReward = user.lockedReward.sub(unlockReward);
            }
            // 删除锁定队列中已解锁的头部元素
            if (deleteHeaderLength > 0) {
                // 删除头部元素
                user.lockedRewardQueue.start = user.lockedRewardQueue.start + deleteHeaderLength;
                // for (uint i = 0; i < deleteHeaderLength; i++) {
                //     removeFirst(queue);
                // }
            }
        }
        // 添加用户当前的锁定奖励
        uint256 pending = user.amount.mul(pool.accPerShare).div(1e12).sub(user.rewardDebt);
        
        if (pending > 0) {
            user.lockedReward = user.lockedReward.add(pending); // 用户总锁定
            uint256 _unlockNumber = currentNumber.add(pool.totalBlockCount).div(pool.dayBlockCount).mul(pool.dayBlockCount); // 解锁高度
            length = queue.end - queue.start;
            if (length == 0) {
                // 锁定队列是空，说明当前是第一次领取或者已经全部解锁，存储到队尾
                enqueue(queue, LockedRewardInfo({
                    amount: pending,
                    unlockNumber: _unlockNumber
                }));
            } else {
                // 本次领取，unlockNumber始终落在今天的区块范围，若队列中最近一次领取是今天的，则累加
                // 否则最近一次是昨天领取或者更以前，此时应该把本次领取的添加到队尾
                LockedRewardInfo storage recently = queue.items[queue.end - 1];
                if (_unlockNumber == recently.unlockNumber) {
                    recently.amount = recently.amount.add(pending);
                } else if (_unlockNumber > recently.unlockNumber) {
                    // 存储到队尾
                    enqueue(queue, LockedRewardInfo({
                        amount: pending,
                        unlockNumber: _unlockNumber
                    }));
                } else {
                    revert("Pending lock error");
                }
            }
        }
    }

    function getLocks(uint256 _pid, address _user) external view returns (uint128 length, uint256[] memory _amounts, uint256[] memory _unlockNumbers) {
        require(_pid < poolInfo.length, "invalid pool id");
        // PoolInfo storage pool = poolInfo[_pid];
        // require(pool.lockDays > 0, "pool is not lock model");

        UserInfo storage user = userInfo[_pid][_user];
        Queue storage queue = user.lockedRewardQueue;
        length = queue.end - queue.start;
        _amounts = new uint256[](length);
        _unlockNumbers = new uint256[](length);
        LockedRewardInfo memory info;
        for (uint128 i = 0; i < length; i++) {
            info = queue.items[i + queue.start];
            _amounts[i] = info.amount;
            _unlockNumbers[i] = info.unlockNumber;
        }
    }
    
    // function getLockSize(uint256 _pid, address _user) external view returns (uint256) {
    //     UserInfo storage user = userInfo[_pid][_user];
    //     Queue storage queue = user.lockedRewardQueue;
    //     uint length = queue.end - queue.start;
    //     return length;
    // }
    
    // 视图函数，查询用户锁定的金额
    function getLockByIndex(uint256 _pid, address _user, uint128 _index) external view returns (uint256 _amount, uint256 _unlockNumber) {
        require(_pid < poolInfo.length, "invalid pool id");
        PoolInfo storage pool = poolInfo[_pid];
        //==0时，没有锁定金额
        if(pool.lockDays == 0) {
            return(0, 0);
        }

        UserInfo storage user = userInfo[_pid][_user];
        Queue storage queue = user.lockedRewardQueue;
        uint length = queue.end - queue.start;
        if (length <= 0) {
            return (0, 0);
        }
        LockedRewardInfo storage recently = queue.items[queue.start + _index];
        return (recently.amount, recently.unlockNumber);
    }
    
    // 视图函数，查询用户最近锁定的金额
    function getRecentlyLock(uint256 _pid, address _user) external view returns (uint256 _amount, uint256 _unlockNumber) {
        require(_pid < poolInfo.length, "invalid pool id");
        PoolInfo storage pool = poolInfo[_pid];
        //==0时，没有锁定金额
        if(pool.lockDays == 0) {
            return(0, 0);
        }

        UserInfo storage user = userInfo[_pid][_user];
        Queue storage queue = user.lockedRewardQueue;
        uint length = queue.end - queue.start;
        if (length <= 0) {
            return (0,0);
        }
        LockedRewardInfo storage recently = queue.items[queue.end - 1];
        return (recently.amount, recently.unlockNumber);
    }

    // 视图函数，计算用户锁定数组中已解锁的金额
    function getUnlockedToken(uint256 _pid, address _user) external view returns (uint256) {
        require(_pid < poolInfo.length, "invalid pool id");
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        //==0时，没有锁定金额，全部返回
        if(pool.lockDays == 0) {
           return calcPendingReward(_pid, _user);
        }

        // 计算用户已解锁的数量
        uint256 unlockReward = 0;
        uint256 currentNumber = block.number;
        Queue storage queue = user.lockedRewardQueue;
        uint length = queue.end - queue.start;
        // 当最近添加的锁定已解锁，说明所有锁定都已解锁
        if (length > 0) {
            if (queue.items[queue.end - 1].unlockNumber <= currentNumber) {
                unlockReward = user.lockedReward;
            }else{
                LockedRewardInfo memory info;
                for (uint128 i = queue.start; i < queue.end; i++) {
                    info = queue.items[i];
                    if (info.unlockNumber > currentNumber) {
                        break;
                    } 
                    unlockReward = unlockReward.add(info.amount);
                }
            } 
        }
        return unlockReward;
    }

    // 视图函数 获取用户质押数量，锁定队列中糖果总量(非实时锁定数量)
    function getUserInfo(uint256 _pid, address _user) external view returns (uint256 _amount, uint256 _rewardDebt, uint128 _lockSize, uint256 _lockedReward) {
        require(_pid < poolInfo.length, "invalid pool id");
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo memory user = userInfo[_pid][_user];
        if(pool.lockDays == 0) {
            return (user.amount, user.rewardDebt, 0, 0);    
        }

        return (user.amount, user.rewardDebt, user.lockedRewardQueue.end - user.lockedRewardQueue.start, user.lockedReward);
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

}