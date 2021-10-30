/**
 *Submitted for verification at Etherscan.io on 2021-10-29
*/

/*
 * Munch single asset staking contract.
 *
 * Visit https://munchproject.io
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
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
        return msg.data;
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
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

// Stake Munch tokens to earn more as rewards.
//
// 
//
contract MunchSAStaking is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct Pool {
        uint256 remainingBalance;   // Funds available for new stakers
        uint256 attributed;         // Funds taken from balance for stakers
        uint256 paidOut;            // Rewards claimed, therefore paidOut <= attributed
        uint256 minStake;
        uint256 maxStake;
        uint stakingDuration;
        uint minPercentToCharity;   // minimum % of rewards being given to charity - 50% is stored as 50
        uint apy;                   // integer percentage - 50% is stored as 50
    }

    struct UserInfo {
        uint256 amountDeposited;
        uint256 remainingRewards;   // Amount not claimed yet
        uint256 rewardsDonated;     // Out of claimed rewards, amount sent to charity
        uint stakingStartTime;      // Timestamp when user started staking
        uint lastRewardTime;        // Last time rewards were claimed
        uint256 rewardDebt;         // Rewards to ignore in redis computation based on when user joined pool
        uint percentToCharity;      // as an int: 50% is stored as 50
    }

    // Address of the ERC20 Token contract.
    IERC20 _munchToken;
    // Address where the sell of the tokens for charity will happen
    address _charityAddress;

    // Counting the accumulated rewards received by the contract so we can
    // redistribute them to users.
    uint256 _accRedisTokensPerShare;
    uint256 _lastRedisTotal;
    uint256 _stakedAndFunds; // Sum of all MUNCH tokens staked or funded for pools
    uint256 _staked; // Sum of all MUNCH tokens staked - used to get redis share of a user

    // All pools added to the contract.
    Pool[] public pools;

    // Info of each user that stakes tokens.
    mapping(uint => mapping(address => UserInfo)) public userInfo;

    event Deposit(uint poolIdx, address indexed user, uint256 amount);
    event Withdraw(uint poolIdx, address indexed user, uint256 amount);

    constructor(address munchToken) {
        _munchToken = IERC20(munchToken);
        _charityAddress = address(_munchToken);
    }

    function addPool(uint stakingDurationInDays, uint256 minStake, uint maxStake, uint apy) public onlyOwner {
        pools.push(Pool({
            remainingBalance: 0,
            attributed: 0,
            paidOut: 0,
            minStake: minStake,
            maxStake: maxStake,
            stakingDuration: stakingDurationInDays * 1 days,
            minPercentToCharity: 50,
            apy: apy
        }));
    }

    // Fund a pool to allow users to participate
    function fund(uint poolIdx, uint256 amount) public onlyOwner {
        Pool storage pool = pools[poolIdx];
        _munchToken.safeTransferFrom(address(msg.sender), address(this), amount);
        pool.remainingBalance = pool.remainingBalance.add(amount);
        _stakedAndFunds = _stakedAndFunds.add(amount);
    }

    // Allows to unlock a pool for any emergency reason. Only accumulated rewards can be redeemed.
    function unlockPool(uint poolIdx) public onlyOwner {
        pools[poolIdx].stakingDuration = 0;
    }

    function setMinPercentToCharity(uint poolIdx, uint minPercentToCharity) public onlyOwner {
        Pool storage pool = pools[poolIdx];
        pool.minPercentToCharity = minPercentToCharity;
    }

    function setCharityAddress(address addy) public onlyOwner {
        _charityAddress = addy;
    }

    // View function to see the expected total rewards for a given address.
    function totalRewards(uint poolIdx, address wallet) external view returns (uint256) {
        UserInfo storage user = userInfo[poolIdx][wallet];
        Pool storage pool = pools[poolIdx];
        return user.amountDeposited.mul(pool.apy).mul(pool.stakingDuration).div(365 days).div(100);
    }

    // View function to see how much can currently be redeemed.
    function pending(uint poolIdx, address wallet) public view returns (uint256) {
        UserInfo storage user = userInfo[poolIdx][wallet];
        Pool storage pool = pools[poolIdx];

        uint timeSinceLastReward = block.timestamp - user.lastRewardTime;
        uint timeFromLastRewardToEnd = user.stakingStartTime + pool.stakingDuration - user.lastRewardTime;
        uint256 pendingReward = user.remainingRewards.mul(timeSinceLastReward).div(timeFromLastRewardToEnd);
        return pendingReward > user.remainingRewards ? user.remainingRewards : pendingReward;
    }

    // View function to see how much redistribution token can currently be redeemed.
    function redisCount(uint poolIdx, address wallet) public view returns (uint256) {
        if (_accRedisTokensPerShare == 0 || _staked == 0) {
            return 0;
        }
        UserInfo storage user = userInfo[poolIdx][wallet];
        return user.amountDeposited.mul(_accRedisTokensPerShare).div(1e36).sub(user.rewardDebt);
    }

    // Update the count of redistribution tokens (coming from MUNCH tx tax)
    // To call BEFORE every change made to the contract balance.
    function updateRedisCount() internal {
        uint256 munchBal = _munchToken.balanceOf(address(this));
        if (munchBal == 0 || _staked == 0) {
            return;
        }

        // Whatever is not part of staked and funded tokens is redistribution.
        // We have not had changes to the total amount between the last call and now.
        uint256 totalRedis = munchBal.sub(_stakedAndFunds);
        uint256 toAccountFor = totalRedis.sub(_lastRedisTotal);
        _lastRedisTotal = totalRedis;

        _accRedisTokensPerShare = _accRedisTokensPerShare.add(toAccountFor.mul(1e36).div(_staked));
    }

    // Deposit tokens to start a staking period.
    // If some tokens are already there, rewards are returned and staking lock starts over with sum of deposits
    //
    // To change the percentage given out to charity, you need to call this function with amount = 0
    // This has the effect of reseting your lock time and withdrawing your rewards.
    function deposit(uint poolIdx, uint256 amount, uint percentToCharity) public {
        UserInfo storage user = userInfo[poolIdx][msg.sender];
        Pool storage pool = pools[poolIdx];
        require(percentToCharity >= pool.minPercentToCharity && percentToCharity <= 100, "Invalid percentage to give to charity");
        uint256 totalDeposit = user.amountDeposited.add(amount);
        require(pool.minStake <= totalDeposit && pool.maxStake >= totalDeposit, "Unauthorized amount");

        if (user.amountDeposited > 0) {
            transferMunchRewards(poolIdx); // this calls updateRedisCount()
        } else {
            updateRedisCount();
        }

        if (amount > 0) {
            uint256 newRewards = amount.mul(pool.apy).mul(pool.stakingDuration).div(365 days).div(100);
            require(pool.remainingBalance >= newRewards, "Pool is full");

            userInfo[poolIdx][msg.sender] = UserInfo({
                amountDeposited: totalDeposit,
                remainingRewards: user.remainingRewards.add(newRewards),
                rewardsDonated: user.rewardsDonated,
                lastRewardTime: block.timestamp,
                stakingStartTime: block.timestamp,
                percentToCharity: percentToCharity,
                rewardDebt: totalDeposit.mul(_accRedisTokensPerShare).div(1e36)
            });
            pool.remainingBalance = pool.remainingBalance.sub(newRewards);
            pool.attributed = pool.attributed.add(newRewards);

            _stakedAndFunds = _stakedAndFunds.add(amount);
            _staked = _staked.add(amount);

            _munchToken.safeTransferFrom(address(msg.sender), address(this), amount);

            emit Deposit(poolIdx, msg.sender, amount);
        } else {
            user.percentToCharity = percentToCharity;
        }
    }

    // Withdraw all staked tokens from a given pool.
    function withdraw(uint poolIdx) public {
        UserInfo storage user = userInfo[poolIdx][msg.sender];
        Pool storage pool = pools[poolIdx];

        require(block.timestamp - user.stakingStartTime > pool.stakingDuration, "Lock period not over");

        // Rewards
        transferMunchRewards(poolIdx); // this calls updateRedisCount()

        // Clean up
        _stakedAndFunds = _stakedAndFunds.sub(user.amountDeposited);
        _staked = _staked.sub(user.amountDeposited);
        user.remainingRewards = 0;
        uint256 amountToWithdraw = user.amountDeposited;
        user.amountDeposited = 0;

        // Withdraw
        _munchToken.safeTransfer(address(msg.sender), amountToWithdraw);
        emit Withdraw(poolIdx, msg.sender, amountToWithdraw);
    }

    // Called both internally and directly to claim rewards for a given wallet.
    // HAS TO call updateRedisCount()
    function transferMunchRewards(uint poolIdx) public {
        UserInfo storage user = userInfo[poolIdx][msg.sender];
        Pool storage pool = pools[poolIdx];
        uint256 pendingRewards = pending(poolIdx, msg.sender);

        updateRedisCount();

        if(pendingRewards > 0) {
            // account for redistribution tokens coming from tx tax on MUNCH token.
            uint256 redis = redisCount(poolIdx, msg.sender);
            uint256 pendingAmount = pendingRewards.add(redis);

            uint256 toCharity = pendingAmount.mul(user.percentToCharity).div(100);
            uint256 toHolder = pendingAmount.sub(toCharity);

            if (toCharity > 0) {
                // send share to charity
                _munchToken.transfer(_charityAddress, toCharity);
            }

            if (toHolder > 0) {
                // send share to holder
                _munchToken.transfer(msg.sender, toHolder);
            }

            // mark as paid out, redeemed, and write down how much was donated to charity
            _stakedAndFunds = _stakedAndFunds.sub(pendingRewards);
            _lastRedisTotal = _lastRedisTotal.sub(redis);
            pool.paidOut = pool.paidOut.add(pendingRewards);
            user.remainingRewards = user.remainingRewards.sub(pendingRewards);
            user.rewardsDonated = user.rewardsDonated.add(toCharity); // includes redis
            user.lastRewardTime = block.timestamp;
        }
    }

    // Withdraw Munch tokens from the funds deposited in a given pool
    // This functions does not allow owner to withdraw funds deposited by or attributed to holders,
    // only remaining funds.
    function fundWithdraw(uint poolIdx, uint256 amount) onlyOwner public {
        Pool storage pool = pools[poolIdx];
        require(pool.remainingBalance >= amount, "Cannot withdraw more than remaining pool balance");
        updateRedisCount();
        _munchToken.transfer(msg.sender, amount);
        _stakedAndFunds = _stakedAndFunds.sub(amount);
    }

    // Withdraw any ETH sent to the contract
    function ethWithdraw() onlyOwner public {
        uint256 balance = address(this).balance;
        require(balance > 0, "Balance is zero.");
        payable(msg.sender).transfer(balance);
    }
}