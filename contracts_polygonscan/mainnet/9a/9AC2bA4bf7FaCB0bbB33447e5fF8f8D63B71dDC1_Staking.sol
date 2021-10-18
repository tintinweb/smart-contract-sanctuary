// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
pragma abicoder v2;

// OpenZeppelin v4
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title Snapshot
 * @author Railgun Contributors
 * @notice Governance contract for railgun, handles staking, voting power, and snapshotting
 * @dev Snapshots cannot be taken during interval 0
 * wait till interval 1 before utilising snapshots
 */
contract Staking {
  using SafeERC20 for IERC20;

  // Constants
  uint256 public constant STAKE_LOCKTIME = 30 days;
  uint256 public constant SNAPSHOT_INTERVAL = 1 days;

  // Staking token
  IERC20 public stakingToken;

  // Time of deployment
  // solhint-disable-next-line var-name-mixedcase
  uint256 public immutable DEPLOY_TIME = block.timestamp;

  // New stake screated
  event Stake(address indexed account, uint256 indexed stakeID, uint256 amount);

  // Stake unlocked (coins removed from voting pool, 30 day delay before claiming is allowed)
  event Unlock(address indexed account, uint256 indexed stakeID);

  // Stake claimed
  event Claim(address indexed account, uint256 indexed stakeID);

  // Delegate claimed
  event Delegate(address indexed owner, address indexed _from, address indexed to, uint256 stakeID, uint256 amount);

  // Total staked
  uint256 public totalStaked = 0;

  // Snapshots for globals
  struct GlobalsSnapshot {
    uint256 interval;
    uint256 totalVotingPower;
    uint256 totalStaked;
  }
  GlobalsSnapshot[] private globalsSnapshots;

  // Stake
  struct StakeStruct {
    address delegate; // Address stake voting power is delegated to
    uint256 amount; // Amount of tokens on this stake
    uint256 staketime; // Time this stake was created
    uint256 locktime; // Time this stake can be claimed (if 0, unlock hasn't been initiated)
    uint256 claimedTime; // Time this stake was claimed (if 0, stake hasn't been claimed)
  }

  // Stake mapping
  // address => stakeID => stake
  mapping(address => StakeStruct[]) public stakes;

  // Voting power for each account
  mapping(address => uint256) public votingPower;

  // Snapshots for accounts
  struct AccountSnapshot {
    uint256 interval;
    uint256 votingPower;
  }
  mapping(address => AccountSnapshot[]) private accountSnapshots;

  /**
   * @notice Sets staking token
   * @param _stakingToken - time to get interval of
   */

  constructor(IERC20 _stakingToken) {
    stakingToken = _stakingToken;

    // Use address 0 to store inverted totalVotingPower
    votingPower[address(0)] = type(uint256).max;
  }

  /**
   * @notice Gets total voting power in system
   * @return totalVotingPower
   */

  function totalVotingPower() public view returns (uint256) {
    return ~votingPower[address(0)];
  }

  /**
   * @notice Gets length of stakes array for address
   * @param _account - address to retrieve stakes array of
   * @return length
   */

  function stakesLength(address _account) external view returns (uint256) {
    return stakes[_account].length;
  }

  /**
   * @notice Gets interval at time
   * @param _time - time to get interval of
   * @return interval
   */

  function intervalAtTime(uint256 _time) public view returns (uint256) {
    require(_time >= DEPLOY_TIME, "Staking: Requested time is before contract was deployed");
    return (_time - DEPLOY_TIME) / SNAPSHOT_INTERVAL;
  }

  /**
   * @notice Gets current interval
   * @return interval
   */

  function currentInterval() public view returns (uint256) {
    return intervalAtTime(block.timestamp);
  }

  /**
   * @notice Returns interval of latest global snapshot
   * @return Latest global snapshot interval
   */

  function latestGlobalsSnapshotInterval() public view returns (uint256) {
    if (globalsSnapshots.length > 0) {
      // If a snapshot exists return the interval it was taken
      return globalsSnapshots[globalsSnapshots.length - 1].interval;
    } else {
      // Else default to 0
      return 0;
    }
  }

  /**
   * @notice Returns interval of latest account snapshot
   * @param _account - account to get latest snapshot of
   * @return Latest account snapshot interval
   */

  function latestAccountSnapshotInterval(address _account) public view returns (uint256) {
    if (accountSnapshots[_account].length > 0) {
      // If a snapshot exists return the interval it was taken
      return accountSnapshots[_account][accountSnapshots[_account].length - 1].interval;
    } else {
      // Else default to 0
      return 0;
    }
  }

  /**
   * @notice Returns length of snapshot array
   * @param _account - account to get snapshot array length of
   * @return Snapshot array length
   */

  function accountSnapshotLength(address _account) external view returns (uint256) {
    return accountSnapshots[_account].length;
  }

  /**
   * @notice Returns length of snapshot array
   * @return Snapshot array length
   */

  function globalsSnapshotLength() external view returns (uint256) {
    return globalsSnapshots.length;
  }

  /**
   * @notice Returns global snapshot at index
   * @param _index - account to get latest snapshot of
   * @return Globals snapshot
   */

  function globalsSnapshot(uint256 _index) external view returns (GlobalsSnapshot memory) {
    return globalsSnapshots[_index];
  }

  /**
   * @notice Returns account snapshot at index
   * @param _account - account to get snapshot of
   * @param _index - index to get snapshot at
   * @return Account snapshot
   */
  function accountSnapshot(address _account, uint256 _index) external view returns (AccountSnapshot memory) {
    return accountSnapshots[_account][_index];
  }

  /**
   * @notice Checks if accoutn and globals snapshots need updating and updates
   * @param _account - Account to take snapshot for
   */
  function snapshot(address _account) internal {
    uint256 _currentInterval = currentInterval();

    // If latest global snapshot is less than current interval, push new snapshot
    if(latestGlobalsSnapshotInterval() < _currentInterval) {
      globalsSnapshots.push(GlobalsSnapshot(
        _currentInterval,
        totalVotingPower(),
        totalStaked
      ));
    }

    // If latest account snapshot is less than current interval, push new snapshot
    // Skip if account is 0 address
    if(_account != address(0) && latestAccountSnapshotInterval(_account) < _currentInterval) {
      accountSnapshots[_account].push(AccountSnapshot(
        _currentInterval,
        votingPower[_account]
      ));
    }
  }

  /**
   * @notice Moves voting power in response to delegation or stake/unstake
   * @param _from - account to move voting power fom
   * @param _to - account to move voting power to
   * @param _amount - amount of voting power to move
   */
  function moveVotingPower(address _from, address _to, uint256 _amount) internal {
    votingPower[_from] -= _amount;
    votingPower[_to] += _amount;
  }

  /**
   * @notice Updates vote delegation
   * @param _stakeID - stake to delegate
   * @param _to - address to delegate to
   */

  function delegate(uint256 _stakeID, address _to) public {
    StakeStruct storage _stake = stakes[msg.sender][_stakeID];

    require(
      _stake.staketime != 0,
      "Staking: Stake doesn't exist"
    );

    require(
      _stake.locktime == 0,
      "Staking: Stake unlocked"
    );

    require(
      _to != address(0),
      "Staking: Can't delegate to 0 address"
    );

    if (_stake.delegate != _to) {
      // Check if snapshot needs to be taken
      snapshot(_stake.delegate); // From
      snapshot(_to); // To

      // Move voting power to delegatee
      moveVotingPower(
        _stake.delegate,
        _to,
        _stake.amount
      );

      // Emit event
      emit Delegate(msg.sender, _stake.delegate, _to, _stakeID, _stake.amount);

      // Update delegation
      _stake.delegate = _to;
    }
  }

  /**
   * @notice Delegates voting power of stake back to self
   * @param _stakeID - stake to delegate back to self
   */

  function undelegate(uint256 _stakeID) external {
    delegate(_stakeID, msg.sender);
  }

  /**
   * @notice Gets global state at interval
   * @param _interval - interval to get state at
   * @return state
   */

  function globalsSnapshotAtSearch(uint256 _interval) internal view returns (GlobalsSnapshot memory) {
    require(_interval <= currentInterval(), "Staking: Interval out of bounds");

    // Index of element
    uint256 index;

    // High/low for binary serach to find index
    // https://en.wikipedia.org/wiki/Binary_search_algorithm
    uint256 low = 0;
    uint256 high = globalsSnapshots.length;

    while (low < high) {
      uint256 mid = Math.average(low, high);

      // Note that mid will always be strictly less than high (i.e. it will be a valid array index)
      // because Math.average rounds down (it does integer division with truncation).
      if (globalsSnapshots[mid].interval > _interval) {
        high = mid;
      } else {
        low = mid + 1;
      }
    }

    // At this point `low` is the exclusive upper bound. Find the inclusive upper bounds and set to index
    if (low > 0 && globalsSnapshots[low - 1].interval == _interval) {
      return globalsSnapshots[low - 1];
    } else {
      index = low;
    }

    // If index is equal to snapshot array length, then no update was made after the requested
    // snapshot interval. This means the latest value is the right one.
    if (index == globalsSnapshots.length) {
      return GlobalsSnapshot(
        _interval,
        totalVotingPower(),
        totalStaked
      );
    } else {
      return globalsSnapshots[index];
    }
  }

  /**
   * @notice Gets global state at interval
   * @param _interval - interval to get state at
   * @param _hint - off-chain computed index of interval
   * @return state
   */

  function globalsSnapshotAt(uint256 _interval, uint256 _hint) external view returns (GlobalsSnapshot memory) {
    require(_interval <= currentInterval(), "Staking: Interval out of bounds");

    // Check if hint is correct, else fall back to binary search
    if (
      _hint <= globalsSnapshots.length
      && (_hint == 0 || globalsSnapshots[_hint - 1].interval < _interval)
      && (_hint == globalsSnapshots.length || globalsSnapshots[_hint].interval >= _interval)
    ) {
    // The hint is correct
      if (_hint < globalsSnapshots.length)
        return globalsSnapshots[_hint];
      else
        return GlobalsSnapshot (_interval, totalVotingPower(), totalStaked);
    } else return globalsSnapshotAtSearch (_interval);
  }


  /**
   * @notice Gets account state at interval
   * @param _account - account to get state for
   * @param _interval - interval to get state at
   * @return state
   */
  function accountSnapshotAtSearch(address _account, uint256 _interval) internal view returns (AccountSnapshot memory) {
    require(_interval <= currentInterval(), "Staking: Interval out of bounds");

    // Get account snapshots array
    AccountSnapshot[] storage snapshots = accountSnapshots[_account];

    // Index of element
    uint256 index;

    // High/low for binary serach to find index
    // https://en.wikipedia.org/wiki/Binary_search_algorithm
    uint256 low = 0;
    uint256 high = snapshots.length;

    while (low < high) {
      uint256 mid = Math.average(low, high);

      // Note that mid will always be strictly less than high (i.e. it will be a valid array index)
      // because Math.average rounds down (it does integer division with truncation).
      if (snapshots[mid].interval > _interval) {
        high = mid;
      } else {
        low = mid + 1;
      }
    }

    // At this point `low` is the exclusive upper bound. Find the inclusive upper bounds and set to index
    if (low > 0 && snapshots[low - 1].interval == _interval) {
      return snapshots[low - 1];
    } else {
      index = low;
    }

    // If index is equal to snapshot array length, then no update was made after the requested
    // snapshot interval. This means the latest value is the right one.
    if (index == snapshots.length) {
      return AccountSnapshot(
        _interval,
        votingPower[_account]
      );
    } else {
      return snapshots[index];
    }
  }


  /**
   * @notice Gets account state at interval
   * @param _account - account to get state for
   * @param _interval - interval to get state at
   * @param _hint - off-chain computed index of interval
   * @return state
   */
  function accountSnapshotAt(address _account, uint256 _interval, uint256 _hint) external view returns (AccountSnapshot memory) {
    require(_interval <= currentInterval(), "Staking: Interval out of bounds");

    // Get account snapshots array
    AccountSnapshot[] storage snapshots = accountSnapshots[_account];

    // Check if hint is correct, else fall back to binary search
    if (
      _hint <= snapshots.length
      && (_hint == 0 || snapshots[_hint - 1].interval < _interval)
      && (_hint == snapshots.length || snapshots[_hint].interval >= _interval)
    ) {
      // The hint is correct
      if (_hint < snapshots.length)
        return snapshots[_hint];
      else
        return AccountSnapshot(_interval, votingPower[_account]);
    } else return accountSnapshotAtSearch(_account, _interval);
  }

  /**
   * @notice Stake tokens
   * @dev This contract should be approve()'d for _amount
   * @param _amount - Amount to stake
   * @return stake ID
   */

  function stake(uint256 _amount) public returns (uint256) {
    // Check if amount is not 0
    require(_amount > 0, "Staking: Amount not set");

    // Check if snapshot needs to be taken
    snapshot(msg.sender);

    // Get stakeID
    uint256 stakeID = stakes[msg.sender].length;

    // Set stake values
    stakes[msg.sender].push(StakeStruct(
      msg.sender,
      _amount,
      block.timestamp,
      0,
      0
    ));

    // Increment global staked
    totalStaked += _amount;

    // Add voting power
    moveVotingPower(
      address(0),
      msg.sender,
      _amount
    );

    // Transfer tokens
    stakingToken.safeTransferFrom(msg.sender, address(this), _amount);

    // Emit event
    emit Stake(msg.sender, stakeID, _amount);

    return stakeID;
  }

  /**
   * @notice Unlock stake tokens
   * @param _stakeID - Stake to unlock
   */

  function unlock(uint256 _stakeID) public {
    require(
      stakes[msg.sender][_stakeID].staketime != 0,
      "Staking: Stake doesn't exist"
    );

    require(
      stakes[msg.sender][_stakeID].locktime == 0,
      "Staking: Stake already unlocked"
    );

    // Check if snapshot needs to be taken
    snapshot(msg.sender);

    // Set stake locktime
    stakes[msg.sender][_stakeID].locktime = block.timestamp + STAKE_LOCKTIME;

    // Remove voting power
    moveVotingPower(
      stakes[msg.sender][_stakeID].delegate,
      address(0),
      stakes[msg.sender][_stakeID].amount
    );

    // Emit event
    emit Unlock(msg.sender, _stakeID);
  }

  /**
   * @notice Claim stake token
   * @param _stakeID - Stake to claim
   */

  function claim(uint256 _stakeID) public {
    require(
      stakes[msg.sender][_stakeID].locktime != 0
      && stakes[msg.sender][_stakeID].locktime < block.timestamp,
      "Staking: Stake not unlocked"
    );

    require(
      stakes[msg.sender][_stakeID].claimedTime == 0,
      "Staking: Stake already claimed"
    );

    // Check if snapshot needs to be taken
    snapshot(msg.sender);

    // Set stake claimed time
    stakes[msg.sender][_stakeID].claimedTime = block.timestamp;

    // Decrement global staked
    totalStaked -= stakes[msg.sender][_stakeID].amount;

    // Transfer tokens
    stakingToken.safeTransfer(
      msg.sender,
      stakes[msg.sender][_stakeID].amount
    );

    // Emit event
    emit Claim(msg.sender, _stakeID);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        // This method relies on extcodesize, which returns 0 for contracts in
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
        return functionCallWithValue(target, data, 0, errorMessage);
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
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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