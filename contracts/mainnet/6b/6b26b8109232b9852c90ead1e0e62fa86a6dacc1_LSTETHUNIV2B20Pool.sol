/**
 *Submitted for verification at Etherscan.io on 2021-02-19
*/

// SPDX-License-Identifier: https://github.com/lendroidproject/protocol.2.0/blob/master/LICENSE.md


// File: @openzeppelin/contracts/math/Math.sol

pragma solidity ^0.7.0;

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

// File: @openzeppelin/contracts/math/SafeMath.sol

pragma solidity ^0.7.0;

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

// File: contracts/heartbeat/Pacemaker.sol

pragma solidity 0.7.5;



/** @title Pacemaker
    @author Lendroid Foundation
    @notice Smart contract based on which various events in the Protocol take place
    @dev Audit certificate : https://certificate.quantstamp.com/view/lendroid-whalestreet
*/


// solhint-disable-next-line
abstract contract Pacemaker {

    using SafeMath for uint256;
    uint256 constant public HEART_BEAT_START_TIME = 1607212800;// 2020-12-06 00:00:00 UTC (UTC +00:00)
    uint256 constant public EPOCH_PERIOD = 8 hours;

    /**
        @notice Displays the epoch which contains the given timestamp
        @return uint256 : Epoch value
    */
    function epochFromTimestamp(uint256 timestamp) public pure returns (uint256) {
        if (timestamp > HEART_BEAT_START_TIME) {
            return timestamp.sub(HEART_BEAT_START_TIME).div(EPOCH_PERIOD).add(1);
        }
        return 0;
    }

    /**
        @notice Displays timestamp when a given epoch began
        @return uint256 : Epoch start time
    */
    function epochStartTimeFromTimestamp(uint256 timestamp) public pure returns (uint256) {
        if (timestamp <= HEART_BEAT_START_TIME) {
            return HEART_BEAT_START_TIME;
        } else {
            return HEART_BEAT_START_TIME.add((epochFromTimestamp(timestamp).sub(1)).mul(EPOCH_PERIOD));
        }
    }

    /**
        @notice Displays timestamp when a given epoch will end
        @return uint256 : Epoch end time
    */
    function epochEndTimeFromTimestamp(uint256 timestamp) public pure returns (uint256) {
        if (timestamp < HEART_BEAT_START_TIME) {
            return HEART_BEAT_START_TIME;
        } else if (timestamp == HEART_BEAT_START_TIME) {
            return HEART_BEAT_START_TIME.add(EPOCH_PERIOD);
        } else {
            return epochStartTimeFromTimestamp(timestamp).add(EPOCH_PERIOD);
        }
    }

    /**
        @notice Calculates current epoch value from the block timestamp
        @dev Calculates the nth 8-hour window frame since the heartbeat's start time
        @return uint256 : Current epoch value
    */
    function currentEpoch() public view returns (uint256) {
        return epochFromTimestamp(block.timestamp);// solhint-disable-line not-rely-on-time
    }

}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.7.0;

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

// File: @openzeppelin/contracts/utils/Address.sol

pragma solidity ^0.7.0;

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

// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol

pragma solidity ^0.7.0;




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

// File: contracts/farming/LPTokenWrapper.sol

pragma solidity 0.7.5;





/** @title LPTokenWrapper
    @author Lendroid Foundation
    @notice Tracks the state of the LP Token staked / unstaked both in total
        and on a per account basis.
    @dev Audit certificate : https://certificate.quantstamp.com/view/lendroid-whalestreet
*/


// solhint-disable-next-line
abstract contract LPTokenWrapper {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;

    IERC20 public lpToken;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    /**
        @notice Registers the LP Token address
        @param lpTokenAddress : address of the LP Token
    */
    // solhint-disable-next-line func-visibility
    constructor(address lpTokenAddress) {
        require(lpTokenAddress.isContract(), "invalid lpTokenAddress");
        lpToken = IERC20(lpTokenAddress);
    }

    /**
        @notice Displays the total LP Token staked
        @return uint256 : value of the _totalSupply which stores total LP Tokens staked
    */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
        @notice Displays LP Token staked per account
        @param account : address of a user account
        @return uint256 : total LP staked by given account address
    */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
        @notice Stake / Deposit LP Token into the Pool
        @dev : Increases count of total LP Token staked.
               Increases count of LP Token staked for the msg.sender.
               LP Token is transferred from msg.sender to the Pool.
        @param amount : Amount of LP Token to stake
    */
    function stake(uint256 amount) public virtual {
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        lpToken.safeTransferFrom(msg.sender, address(this), amount);
    }

    /**
        @notice Unstake / Withdraw staked LP Token from the Pool
        @dev : Decreases count of total LP Token staked
               Decreases count of LP Token staked for the msg.sender
               LP Token is transferred from the Pool to the msg.sender
        @param amount : Amount of LP Token to withdraw / unstake
    */
    function unstake(uint256 amount) public virtual {
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        lpToken.safeTransfer(msg.sender, amount);
    }
}

// File: contracts/farming/BasePool.sol

pragma solidity 0.7.5;





/** @title BasePool
    @author Lendroid Foundation
    @notice Inherits the LPTokenWrapper contract, performs additional functions
        on the stake and unstake functions, and includes logic to calculate and
        withdraw rewards.
        This contract is inherited by all Pool contracts.
    @dev Audit certificate : https://certificate.quantstamp.com/view/lendroid-whalestreet
*/


// solhint-disable-next-line
abstract contract BasePool is LPTokenWrapper, Pacemaker {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;

    string public poolName;
    IERC20 public rewardToken;

    uint256 public lastUpdateTime;
    uint256 public cachedRewardPerStake;

    mapping(address => uint256) public userRewardPerStakePaid;
    mapping(address => uint256) public lastEpochStaked;
    mapping(address => uint256) public rewards;

    uint256 public startTime = HEART_BEAT_START_TIME;// 2020-12-04 00:00:00 (UTC UTC +00:00)

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event RewardClaimed(address indexed user, uint256 reward);

    /**
        @notice Registers the Pool name, Reward Token address, and LP Token address.
        @param name : Name of the Pool
        @param rewardTokenAddress : address of the Reward Token
        @param lpTokenAddress : address of the LP Token
    */
    // solhint-disable-next-line func-visibility
    constructor(string memory name, address rewardTokenAddress, address lpTokenAddress) LPTokenWrapper(lpTokenAddress) {
        require(rewardTokenAddress.isContract(), "invalid rewardTokenAddress");
        rewardToken = IERC20(rewardTokenAddress);
        // It's OK for the pool name to be empty.
        poolName = name;
    }

    /**
        @notice modifier to check if the startTime has been reached
        @dev Pacemaker.currentEpoch() returns values > 0 only from
            HEART_BEAT_START_TIME+1. Therefore, staking is possible only from
            epoch 1
    */
    modifier checkStart() {
        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp > startTime, "startTime has not been reached");
        _;
    }

    /**
        @notice Unstake the staked LP Token and claim corresponding earnings from the Pool
        @dev : Perform actions from unstake()
               Perform actions from claim()
    */
    function unstakeAndClaim() external updateRewards(msg.sender) checkStart {
        unstake(balanceOf(msg.sender));
        claim();
    }

    /**
        @notice Displays reward tokens per Lp token staked. Useful to display APY on the frontend
    */
    function rewardPerStake() public view returns (uint256) {
        if (totalSupply() == 0) {
            return cachedRewardPerStake;
        }
        // solhint-disable-next-line not-rely-on-time
        return cachedRewardPerStake.add(block.timestamp.sub(lastUpdateTime).mul(
                rewardRate(currentEpoch())).mul(1e18).div(totalSupply())
            );
    }

    /**
        @notice Displays earnings of an address so far. Useful to display claimable rewards on the frontend
        @param account : the given user address
        @return earnings of given address
    */
    function earned(address account) public view returns (uint256) {
        return balanceOf(account).mul(rewardPerStake().sub(
            userRewardPerStakePaid[account])).div(1e18).add(rewards[account]);
    }

    /**
        @notice modifier to update system and user info whenever a user makes a
            function call to stake, unstake, claim or unstakeAndClaim.
        @dev Updates rewardPerStake and time when system is updated
            Recalculates user rewards
    */
    modifier updateRewards(address account) {
        cachedRewardPerStake = rewardPerStake();
        lastUpdateTime = block.timestamp;// solhint-disable-line not-rely-on-time
        rewards[account] = earned(account);
        userRewardPerStakePaid[account] = cachedRewardPerStake;
        _;
    }

    /**
        @notice Displays reward tokens per second for a given epoch. This
        function is implemented in contracts that inherit this contract.
    */
    function rewardRate(uint256 epoch) public pure virtual returns (uint256);

    /**
        @notice Stake / Deposit LP Token into the Pool.
        @dev Increases count of total LP Token staked in the current epoch.
             Increases count of LP Token staked for the caller in the current epoch.
             Register that caller last staked in the current epoch.
             Perform actions from BasePool.stake().
        @param amount : Amount of LP Token to stake
    */
    function stake(uint256 amount) public checkStart updateRewards(msg.sender) override {
        require(amount > 0, "Cannot stake 0");
        lastEpochStaked[msg.sender] = currentEpoch();
        super.stake(amount);
        emit Staked(msg.sender, amount);
    }

    /**
        @notice Unstake / Withdraw staked LP Token from the Pool
        @inheritdoc LPTokenWrapper
    */
    function unstake(uint256 amount) public checkStart updateRewards(msg.sender) override {
        require(amount > 0, "Cannot unstake 0");
        require(lastEpochStaked[msg.sender] < currentEpoch(), "Cannot unstake in staked epoch.");
        super.unstake(amount);
        emit Unstaked(msg.sender, amount);
    }

    /**
        @notice Transfers earnings from previous epochs to the caller
    */
    function claim() public checkStart updateRewards(msg.sender) {
        require(rewards[msg.sender] > 0, "No rewards to claim");
        uint256 rewardsEarned = rewards[msg.sender];
        rewards[msg.sender] = 0;
        rewardToken.safeTransfer(msg.sender, rewardsEarned);
        emit RewardClaimed(msg.sender, rewardsEarned);
    }

}

// File: contracts/farming/LSTETHUNIV2B20Pool.sol

pragma solidity 0.7.5;



/** @title $HRIMPETHUNIV2B20Pool
    @author Lendroid Foundation
    @notice Inherits the BasePool contract, and contains reward distribution
        logic for the B20 token.
*/


// solhint-disable-next-line
contract LSTETHUNIV2B20Pool is BasePool {

    using SafeMath for uint256;

    /**
        @notice Registers the Pool name as B20ETHUNIV2B20Pool as Pool name,
                LST-WETH-UNIV2 as the LP Token, and
                B20 as the Reward Token.
        @param rewardTokenAddress : B20 Token address
        @param lpTokenAddress : LST-WETH-UNIV2 Token address
    */
    // solhint-disable-next-line func-visibility
    constructor(address rewardTokenAddress, address lpTokenAddress) BasePool("LSTETHUNIV2B20Pool",
        rewardTokenAddress, lpTokenAddress) {}// solhint-disable-line no-empty-blocks

    /**
        @notice Displays total B20 rewards distributed per second in a given epoch.
        @dev Series 1 :
                Epochs : 162-254
                Total B20 distributed : 18,750
                Distribution duration : 31 days and 8 hours (Jan 28:16:00 to Feb 29 59:59:59 GMT)
            Series 2 :
                Epochs : 255-347
                Total B20 distributed : 11,250
                Distribution duration : 31 days (Mar 1 00:00:00 GMT to Mar 31 59:59:59 GMT)
            Series 3 :
                Epochs : 348-437
                Total B20 distributed : 7,500
                Distribution duration : 30 days (Apr 1 00:00:00 GMT to Apr 30 59:59:59 GMT)
        @param epoch : 8-hour window number
        @return B20 Tokens distributed per second during the given epoch
    */
    function rewardRate(uint256 epoch) public pure override returns (uint256) {
        uint256 seriesRewards = 0;
        require(epoch > 0, "epoch cannot be 0");
        if (epoch > 161 && epoch <= 254) {
            seriesRewards = 18750;// 18,750
            return seriesRewards.mul(1e18).div(752 hours);
        } else if (epoch > 254 && epoch <= 347) {
            seriesRewards = 11250;// 11,250
            return seriesRewards.mul(1e18).div(31 days);
        } else if (epoch > 347 && epoch <= 437) {
            seriesRewards = 7500;// 7,500
            return seriesRewards.mul(1e18).div(30 days);
        } else {
            return 0;
        }
    }

}