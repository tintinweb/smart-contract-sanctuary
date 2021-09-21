// SPDX-License-Identifier: MIT
pragma solidity >=0.6.10 <0.8.0;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";

import "./SafeDecimalMath.sol";
import "./CoreUtility.sol";

import "./IVotingEscrow.sol";

contract FeeDistributor is CoreUtility, Ownable {
    using SafeMath for uint256;
    using SafeDecimalMath for uint256;
    using SafeERC20 for IERC20;

    /// @notice 60% as the max admin fee rate
    uint256 public constant MAX_ADMIN_FEE_RATE = 6e17;

    uint256 private immutable _maxTime;
    IERC20 public immutable rewardToken;
    IVotingEscrow public immutable votingEscrow;

    /// @notice Receiver for admin fee
    address public admin;

    /// @notice Admin fee rate
    uint256 public adminFeeRate;

    /// @notice Timestamp of the last checkpoint
    uint256 public checkpointTimestamp;

    /// @notice Mapping of unlockTime => total amount that will be unlocked at unlockTime
    mapping(uint256 => uint256) public scheduledUnlock;

    /// @notice Amount of Chess locked at the end of the last checkpoint's week
    uint256 public nextWeekLocked;

    /// @notice Total veCHESS at the end of the last checkpoint's week
    uint256 public nextWeekSupply;

    /// @notice Cumulative rewards received until the last checkpoint minus cumulative rewards
    ///         claimed until now
    uint256 public lastRewardBalance;

    /// @notice Mapping of week => total rewards accumulated
    ///
    ///         Key is the start timestamp of a week on each Thursday. Value is
    ///         the rewards collected from the corresponding fund in rewardToken's unit
    mapping(uint256 => uint256) public rewardsPerWeek;

    /// @notice Mapping of week => vote-locked chess total supplies
    ///
    ///         Key is the start timestamp of a week on each Thursday. Value is
    ///         vote-locked chess total supplies captured at the start of each week
    mapping(uint256 => uint256) public veSupplyPerWeek;

    /// @notice Locked balance of an account, which is synchronized with `VotingEscrow` when
    ///         `syncWithVotingEscrow()` is called
    mapping(address => IVotingEscrow.LockedBalance) public userLockedBalances;

    /// @notice Start timestamp of the week of a user's last checkpoint
    mapping(address => uint256) public userWeekCursors;

    /// @notice An account's veCHESS amount at the beginning of the week of this user's
    ///         last checkpoint
    mapping(address => uint256) public userLastBalances;

    /// @notice Mapping of account => amount of claimable Chess
    mapping(address => uint256) public claimableRewards;

    event Synchronized(
        address indexed account,
        uint256 oldAmount,
        uint256 oldUnlockTime,
        uint256 newAmount,
        uint256 newUnlockTime
    );

    constructor(
        address rewardToken_,
        address votingEscrow_,
        address admin_,
        uint256 adminFeeRate_
    ) public {
        require(adminFeeRate_ <= MAX_ADMIN_FEE_RATE, "Cannot exceed max admin fee rate");
        rewardToken = IERC20(rewardToken_);
        votingEscrow = IVotingEscrow(votingEscrow_);
        _maxTime = IVotingEscrow(votingEscrow_).maxTime();
        admin = admin_;
        adminFeeRate = adminFeeRate_;
        checkpointTimestamp = block.timestamp;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balanceAtTimestamp(userLockedBalances[account], block.timestamp);
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupplyAtTimestamp(block.timestamp);
    }

    function balanceOfAtTimestamp(address account, uint256 timestamp)
        external
        view
        returns (uint256)
    {
        require(timestamp >= checkpointTimestamp, "Must be current or future time");
        return _balanceAtTimestamp(userLockedBalances[account], timestamp);
    }

    function totalSupplyAtTimestamp(uint256 timestamp) external view returns (uint256) {
        require(timestamp >= checkpointTimestamp, "Must be current or future time");
        return _totalSupplyAtTimestamp(timestamp);
    }

    /// @dev Calculate the amount of veCHESS of a `LockedBalance` at a given timestamp
    function _balanceAtTimestamp(
        IVotingEscrow.LockedBalance memory lockedBalance,
        uint256 timestamp
    ) private view returns (uint256) {
        if (timestamp >= lockedBalance.unlockTime) {
            return 0;
        }
        return lockedBalance.amount.mul(lockedBalance.unlockTime - timestamp) / _maxTime;
    }

    function _totalSupplyAtTimestamp(uint256 timestamp) private view returns (uint256) {
        uint256 total = 0;
        for (
            uint256 weekCursor = _endOfWeek(timestamp);
            weekCursor <= timestamp + _maxTime;
            weekCursor += 1 weeks
        ) {
            total = total.add((scheduledUnlock[weekCursor].mul(weekCursor - timestamp)) / _maxTime);
        }
        return total;
    }

    /// @notice Synchronize an account's locked Chess with `VotingEscrow`.
    /// @param account Address of the synchronized account
    function syncWithVotingEscrow(address account) external {
        userCheckpoint(account);

        uint256 nextWeek = _endOfWeek(block.timestamp);
        IVotingEscrow.LockedBalance memory newLockedBalance =
            votingEscrow.getLockedBalance(account);
        if (newLockedBalance.amount == 0 || newLockedBalance.unlockTime <= nextWeek) {
            return;
        }
        IVotingEscrow.LockedBalance memory oldLockedBalance = userLockedBalances[account];
        uint256 newNextWeekLocked = nextWeekLocked;
        uint256 newNextWeekSupply = nextWeekSupply;

        // Remove the old schedule if there is one
        if (oldLockedBalance.amount > 0 && oldLockedBalance.unlockTime > nextWeek) {
            scheduledUnlock[oldLockedBalance.unlockTime] = scheduledUnlock[
                oldLockedBalance.unlockTime
            ]
                .sub(oldLockedBalance.amount);
            newNextWeekLocked = newNextWeekLocked.sub(oldLockedBalance.amount);
            newNextWeekSupply = newNextWeekSupply.sub(
                oldLockedBalance.amount.mul(oldLockedBalance.unlockTime - nextWeek) / _maxTime
            );
        }

        scheduledUnlock[newLockedBalance.unlockTime] = scheduledUnlock[newLockedBalance.unlockTime]
            .add(newLockedBalance.amount);
        nextWeekLocked = newNextWeekLocked.add(newLockedBalance.amount);
        // Round up on division when added to the total supply, so that the total supply is never
        // smaller than the sum of all accounts' veCHESS balance.
        nextWeekSupply = newNextWeekSupply.add(
            newLockedBalance.amount.mul(newLockedBalance.unlockTime - nextWeek).add(_maxTime - 1) /
                _maxTime
        );
        userLockedBalances[account] = newLockedBalance;

        emit Synchronized(
            account,
            oldLockedBalance.amount,
            oldLockedBalance.unlockTime,
            newLockedBalance.amount,
            newLockedBalance.unlockTime
        );
    }

    function userCheckpoint(address account) public returns (uint256 rewards) {
        checkpoint();
        rewards = claimableRewards[account].add(_rewardCheckpoint(account));
        claimableRewards[account] = rewards;
    }

    function claimRewards(address account) external returns (uint256 rewards) {
        checkpoint();
        rewards = claimableRewards[account].add(_rewardCheckpoint(account));
        claimableRewards[account] = 0;
        lastRewardBalance = lastRewardBalance.sub(rewards);
        rewardToken.safeTransfer(account, rewards);
    }

    /// @notice Make a global checkpoint. If the period since the last checkpoint spans over
    ///         multiple weeks, rewards received in this period are split into these weeks
    ///         proportional to the time in each week.
    /// @dev Post-conditions:
    ///
    ///      - `checkpointTimestamp == block.timestamp`
    ///      - `lastRewardBalance == rewardToken.balanceOf(address(this))`
    ///      - All `rewardsPerWeek[t]` are updated, where `t <= checkpointTimestamp`
    ///      - All `veSupplyPerWeek[t]` are set, where `t <= checkpointTimestamp`
    ///      - `nextWeekSupply` is the total veCHESS at the end of this week
    ///      - `nextWeekLocked` is the total locked Chess at the end of this week
    function checkpoint() public {
        uint256 tokenBalance = rewardToken.balanceOf(address(this));
        uint256 tokensToDistribute = tokenBalance.sub(lastRewardBalance);
        lastRewardBalance = tokenBalance;

        uint256 adminFee = tokensToDistribute.multiplyDecimal(adminFeeRate);
        if (adminFee > 0) {
            claimableRewards[admin] = claimableRewards[admin].add(adminFee);
            tokensToDistribute = tokensToDistribute.sub(adminFee);
        }
        uint256 rewardTime = checkpointTimestamp;
        uint256 weekCursor = _endOfWeek(rewardTime) - 1 weeks;
        uint256 currentWeek = _endOfWeek(block.timestamp) - 1 weeks;

        // Update veCHESS supply at the beginning of each week since the last checkpoint.
        if (weekCursor < currentWeek) {
            uint256 newLocked = nextWeekLocked;
            uint256 newSupply = nextWeekSupply;
            for (uint256 w = weekCursor + 1 weeks; w <= currentWeek; w += 1 weeks) {
                veSupplyPerWeek[w] = newSupply;
                // Calculate supply at the end of the next week.
                newSupply = newSupply.sub(newLocked.mul(1 weeks) / _maxTime);
                // Remove Chess unlocked at the end of the next week from total locked amount.
                newLocked = newLocked.sub(scheduledUnlock[w + 1 weeks]);
            }
            nextWeekLocked = newLocked;
            nextWeekSupply = newSupply;
        }

        // Distribute rewards received since the last checkpoint.
        if (tokensToDistribute > 0) {
            if (weekCursor >= currentWeek) {
                rewardsPerWeek[weekCursor] = rewardsPerWeek[weekCursor].add(tokensToDistribute);
            } else {
                uint256 sinceLast = block.timestamp - rewardTime;
                // Calculate the fraction of rewards proportional to the time from
                // the last checkpoint to the end of that week.
                rewardsPerWeek[weekCursor] = rewardsPerWeek[weekCursor].add(
                    tokensToDistribute.mul(weekCursor + 1 weeks - rewardTime) / sinceLast
                );
                weekCursor += 1 weeks;
                // Calculate the fraction of rewards for intermediate whole weeks.
                while (weekCursor < currentWeek) {
                    rewardsPerWeek[weekCursor] = tokensToDistribute.mul(1 weeks) / sinceLast;
                    weekCursor += 1 weeks;
                }
                // Calculate the fraction of rewards proportional to the time from
                // the beginning of the current week to the current block timestamp.
                rewardsPerWeek[weekCursor] =
                    tokensToDistribute.mul(block.timestamp - weekCursor) /
                    sinceLast;
            }
        }

        checkpointTimestamp = block.timestamp;
    }

    function updateAdmin(address newAdmin) external onlyOwner {
        admin = newAdmin;
    }

    function updateAdminFeeRate(uint256 newAdminFeeRate) external onlyOwner {
        require(newAdminFeeRate <= MAX_ADMIN_FEE_RATE, "Cannot exceed max admin fee rate");
        adminFeeRate = newAdminFeeRate;
    }

    /// @dev Calculate rewards since a user's last checkpoint and make a new checkpoint.
    ///
    ///      Post-conditions:
    ///
    ///      - `userWeekCursor[account]` is the start timestamp of the current week
    ///      - `userLastBalances[account]` is amount of veCHESS at the beginning of the current week
    /// @param account Address of the account
    /// @return Rewards since the last checkpoint
    function _rewardCheckpoint(address account) private returns (uint256) {
        uint256 currentWeek = _endOfWeek(block.timestamp) - 1 weeks;
        uint256 weekCursor = userWeekCursors[account];
        if (weekCursor >= currentWeek) {
            return 0;
        }
        if (weekCursor == 0) {
            userWeekCursors[account] = currentWeek;
            return 0;
        }

        // The week of the last user checkpoint has ended.
        uint256 lastBalance = userLastBalances[account];
        uint256 rewards =
            lastBalance > 0
                ? lastBalance.mul(rewardsPerWeek[weekCursor]) / veSupplyPerWeek[weekCursor]
                : 0;
        weekCursor += 1 weeks;

        // Iterate over succeeding weeks and calculate rewards.
        IVotingEscrow.LockedBalance memory lockedBalance = userLockedBalances[account];
        while (weekCursor < currentWeek) {
            uint256 veChessBalance = _balanceAtTimestamp(lockedBalance, weekCursor);
            if (veChessBalance == 0) {
                break;
            }
            // A positive veChessBalance guarentees that veSupply of that week is also positive
            rewards = rewards.add(
                veChessBalance.mul(rewardsPerWeek[weekCursor]) / veSupplyPerWeek[weekCursor]
            );
            weekCursor += 1 weeks;
        }

        userWeekCursors[account] = currentWeek;
        userLastBalances[account] = _balanceAtTimestamp(lockedBalance, currentWeek);
        return rewards;
    }

    /// @notice Recalculate `nextWeekSupply` from scratch. This function eliminates accumulated
    ///         rounding errors in `nextWeekSupply`, which is incrementally updated in
    ///         `syncWithVotingEscrow()` and `checkpoint()`. It is almost never required.
    /// @dev See related test cases for details about the rounding errors.
    function calibrateSupply() external {
        uint256 nextWeek = _endOfWeek(checkpointTimestamp);
        nextWeekSupply = _totalSupplyAtTimestamp(nextWeek);
    }
}