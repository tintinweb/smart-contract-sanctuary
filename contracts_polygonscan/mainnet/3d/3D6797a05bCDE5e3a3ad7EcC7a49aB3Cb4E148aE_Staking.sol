// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Math.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

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
    event Stake(
        address indexed account,
        uint256 indexed stakeID,
        uint256 amount
    );

    // Stake unlocked (coins removed from voting pool, 30 day delay before claiming is allowed)
    event Unlock(address indexed account, uint256 indexed stakeID);

    // Stake claimed
    event Claim(address indexed account, uint256 indexed stakeID);

    // Delegate claimed
    event Delegate(
        address indexed owner,
        address indexed _from,
        address indexed to,
        uint256 stakeID,
        uint256 amount
    );

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
        require(
            _time >= DEPLOY_TIME,
            "Staking: Requested time is before contract was deployed"
        );
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

    function latestAccountSnapshotInterval(address _account)
        public
        view
        returns (uint256)
    {
        if (accountSnapshots[_account].length > 0) {
            // If a snapshot exists return the interval it was taken
            return
                accountSnapshots[_account][
                    accountSnapshots[_account].length - 1
                ].interval;
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

    function accountSnapshotLength(address _account)
        external
        view
        returns (uint256)
    {
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

    function globalsSnapshot(uint256 _index)
        external
        view
        returns (GlobalsSnapshot memory)
    {
        return globalsSnapshots[_index];
    }

    /**
     * @notice Returns account snapshot at index
     * @param _account - account to get snapshot of
     * @param _index - index to get snapshot at
     * @return Account snapshot
     */
    function accountSnapshot(address _account, uint256 _index)
        external
        view
        returns (AccountSnapshot memory)
    {
        return accountSnapshots[_account][_index];
    }

    /**
     * @notice Checks if accoutn and globals snapshots need updating and updates
     * @param _account - Account to take snapshot for
     */
    function snapshot(address _account) internal {
        uint256 _currentInterval = currentInterval();

        // If latest global snapshot is less than current interval, push new snapshot
        if (latestGlobalsSnapshotInterval() < _currentInterval) {
            globalsSnapshots.push(
                GlobalsSnapshot(
                    _currentInterval,
                    totalVotingPower(),
                    totalStaked
                )
            );
        }

        // If latest account snapshot is less than current interval, push new snapshot
        // Skip if account is 0 address
        if (
            _account != address(0) &&
            latestAccountSnapshotInterval(_account) < _currentInterval
        ) {
            accountSnapshots[_account].push(
                AccountSnapshot(_currentInterval, votingPower[_account])
            );
        }
    }

    /**
     * @notice Moves voting power in response to delegation or stake/unstake
     * @param _from - account to move voting power fom
     * @param _to - account to move voting power to
     * @param _amount - amount of voting power to move
     */
    function moveVotingPower(
        address _from,
        address _to,
        uint256 _amount
    ) internal {
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

        require(_stake.staketime != 0, "Staking: Stake doesn't exist");

        require(_stake.locktime == 0, "Staking: Stake unlocked");

        require(_to != address(0), "Staking: Can't delegate to 0 address");

        if (_stake.delegate != _to) {
            // Check if snapshot needs to be taken
            snapshot(_stake.delegate); // From
            snapshot(_to); // To

            // Move voting power to delegatee
            moveVotingPower(_stake.delegate, _to, _stake.amount);

            // Emit event
            emit Delegate(
                msg.sender,
                _stake.delegate,
                _to,
                _stakeID,
                _stake.amount
            );

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

    function globalsSnapshotAtSearch(uint256 _interval)
        internal
        view
        returns (GlobalsSnapshot memory)
    {
        require(
            _interval <= currentInterval(),
            "Staking: Interval out of bounds"
        );

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
            return GlobalsSnapshot(_interval, totalVotingPower(), totalStaked);
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

    function globalsSnapshotAt(uint256 _interval, uint256 _hint)
        external
        view
        returns (GlobalsSnapshot memory)
    {
        require(
            _interval <= currentInterval(),
            "Staking: Interval out of bounds"
        );

        // Check if hint is correct, else fall back to binary search
        if (
            _hint <= globalsSnapshots.length &&
            (_hint == 0 || globalsSnapshots[_hint - 1].interval < _interval) &&
            (_hint == globalsSnapshots.length ||
                globalsSnapshots[_hint].interval >= _interval)
        ) {
            // The hint is correct
            if (_hint < globalsSnapshots.length) return globalsSnapshots[_hint];
            else
                return
                    GlobalsSnapshot(_interval, totalVotingPower(), totalStaked);
        } else return globalsSnapshotAtSearch(_interval);
    }

    /**
     * @notice Gets account state at interval
     * @param _account - account to get state for
     * @param _interval - interval to get state at
     * @return state
     */
    function accountSnapshotAtSearch(address _account, uint256 _interval)
        internal
        view
        returns (AccountSnapshot memory)
    {
        require(
            _interval <= currentInterval(),
            "Staking: Interval out of bounds"
        );

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
            return AccountSnapshot(_interval, votingPower[_account]);
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
    function accountSnapshotAt(
        address _account,
        uint256 _interval,
        uint256 _hint
    ) external view returns (AccountSnapshot memory) {
        require(
            _interval <= currentInterval(),
            "Staking: Interval out of bounds"
        );

        // Get account snapshots array
        AccountSnapshot[] storage snapshots = accountSnapshots[_account];

        // Check if hint is correct, else fall back to binary search
        if (
            _hint <= snapshots.length &&
            (_hint == 0 || snapshots[_hint - 1].interval < _interval) &&
            (_hint == snapshots.length ||
                snapshots[_hint].interval >= _interval)
        ) {
            // The hint is correct
            if (_hint < snapshots.length) return snapshots[_hint];
            else return AccountSnapshot(_interval, votingPower[_account]);
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
        stakes[msg.sender].push(
            StakeStruct(msg.sender, _amount, block.timestamp, 0, 0)
        );

        // Increment global staked
        totalStaked += _amount;

        // Add voting power
        moveVotingPower(address(0), msg.sender, _amount);

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
        stakes[msg.sender][_stakeID].locktime =
            block.timestamp +
            STAKE_LOCKTIME;

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
            stakes[msg.sender][_stakeID].locktime != 0 &&
                stakes[msg.sender][_stakeID].locktime < block.timestamp,
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