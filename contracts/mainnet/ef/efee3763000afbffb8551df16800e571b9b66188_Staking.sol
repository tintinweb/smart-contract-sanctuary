//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./GlobalsAndUtility.sol";
import "./helpers/IERC20Burnable.sol";

contract Staking is GlobalsAndUtility {
    using SafeERC20 for IERC20Burnable;

    constructor(
        IERC20Burnable _stakingToken, // MUST BE BURNABLE
        uint40 _launchTime,
        address _originAddr
    )
    {
        require(IERC20Metadata(address(_stakingToken)).decimals() == TOKEN_DECIMALS, "STAKING: incompatible token decimals");
        //require(_launchTime >= block.timestamp, "STAKING: launch must be in future");
        require(_originAddr != address(0), "STAKING: origin address is 0");

        stakingToken = _stakingToken;
        launchTime = _launchTime;
        originAddr = _originAddr;

        /* Initialize global shareRate to 1 */
        globals.shareRate = uint40(1 * SHARE_RATE_SCALE);
    }

    /**
     * @dev PUBLIC FACING: Open a stake.
     * @param newStakedAmount Amount of staking token to stake
     * @param newStakedDays Number of days to stake
     */
    function stakeStart(uint256 newStakedAmount, uint256 newStakedDays)
        external
    {
        GlobalsCache memory g;
        _globalsLoad(g);

        /* Enforce the minimum stake time */
        require(newStakedDays >= MIN_STAKE_DAYS, "STAKING: newStakedDays lower than minimum");
        /* Enforce the maximum stake time */
        require(newStakedDays <= MAX_STAKE_DAYS, "STAKING: newStakedDays higher than maximum");

        /* Check if log data needs to be updated */
        _dailyDataUpdateAuto(g);

        _stakeStart(g, newStakedAmount, newStakedDays);

        /* Remove staked amount from balance of staker */
        stakingToken.safeTransferFrom(msg.sender, address(this), newStakedAmount);

        _globalsSync(g);
    }

    /**
     * @dev PUBLIC FACING: Unlocks a completed stake, distributing the proceeds of any penalty
     * immediately. The staker must still call stakeEnd() to retrieve their stake return (if any).
     * @param stakerAddr Address of staker
     * @param stakeIndex Index of stake within stake list
     * @param stakeIdParam The stake's id
     */
    function stakeGoodAccounting(address stakerAddr, uint256 stakeIndex, uint40 stakeIdParam)
        external
    {
        GlobalsCache memory g;
        _globalsLoad(g);

        /* require() is more informative than the default assert() */
        require(stakeLists[stakerAddr].length != 0, "STAKING: Empty stake list");
        require(stakeIndex < stakeLists[stakerAddr].length, "STAKING: stakeIndex invalid");

        StakeStore storage stRef = stakeLists[stakerAddr][stakeIndex];

        /* Get stake copy */
        StakeCache memory st;
        _stakeLoad(stRef, stakeIdParam, st);

        /* Stake must have served full term */
        require(g._currentDay >= st._lockedDay + st._stakedDays, "STAKING: Stake not fully served");

        /* Stake must still be locked */
        require(st._unlockedDay == 0, "STAKING: Stake already unlocked");

        /* Check if log data needs to be updated */
        _dailyDataUpdateAuto(g);

        /* Unlock the completed stake */
        _stakeUnlock(g, st);

        /* stakeReturn value is unused here */
        (, uint256 payout, uint256 penalty, uint256 cappedPenalty) = _stakePerformance(
            st,
            st._stakedDays
        );

        emit StakeGoodAccounting(
            stakerAddr,
            stakeIdParam,
            msg.sender,
            uint40(block.timestamp),
            uint128(st._stakedAmount),
            uint128(st._stakeShares),
            uint128(payout),
            uint128(penalty)
        );

        if (cappedPenalty != 0) {
            _splitPenaltyProceeds(g, cappedPenalty);
        }

        /* st._unlockedDay has changed */
        _stakeUpdate(stRef, st);

        _globalsSync(g);
    }

    /**
     * @dev PUBLIC FACING: Closes a stake. The order of the stake list can change so
     * a stake id is used to reject stale indexes.
     * @param stakeIndex Index of stake within stake list
     * @param stakeIdParam The stake's id
     * @return stakeReturn payout penalty
     */
    function stakeEnd(uint256 stakeIndex, uint40 stakeIdParam)
        external
        returns (uint256 stakeReturn, uint256 payout, uint256 penalty, uint256 cappedPenalty)
    {
        GlobalsCache memory g;
        _globalsLoad(g);

        StakeStore[] storage stakeListRef = stakeLists[msg.sender];

        /* require() is more informative than the default assert() */
        require(stakeListRef.length != 0, "STAKING: Empty stake list");
        require(stakeIndex < stakeListRef.length, "STAKING: stakeIndex invalid");

        /* Get stake copy */
        StakeCache memory st;
        _stakeLoad(stakeListRef[stakeIndex], stakeIdParam, st);

        /* Check if log data needs to be updated */
        _dailyDataUpdateAuto(g);

        require(g._currentDay >= st._lockedDay + HARD_LOCK_DAYS, "STAKING: hard lock period");

        uint256 servedDays = 0;
        bool prevUnlocked = (st._unlockedDay != 0);

        if (prevUnlocked) {
            /* Previously unlocked in stakeGoodAccounting(), so must have served full term */
            servedDays = st._stakedDays;
        } else {
            _stakeUnlock(g, st);

            servedDays = g._currentDay - st._lockedDay;
            if (servedDays > st._stakedDays) {
                servedDays = st._stakedDays;
            }
        }

        (stakeReturn, payout, penalty, cappedPenalty) = _stakePerformance(st, servedDays);

        emit StakeEnd(
            msg.sender,
            stakeIdParam,
            uint40(block.timestamp),
            uint128(st._stakedAmount),
            uint128(st._stakeShares),
            uint128(payout),
            uint128(penalty),
            uint16(servedDays),
            prevUnlocked
        );

        if (cappedPenalty != 0 && !prevUnlocked) {
            /* Split penalty proceeds only if not previously unlocked by stakeGoodAccounting() */
            _splitPenaltyProceeds(g, cappedPenalty);
        }

        /* Pay the stake return, if any, to the staker */
        if (stakeReturn != 0) {
            stakingToken.safeTransfer(msg.sender, stakeReturn);

            /* Update the share rate if necessary */
            _shareRateUpdate(g, st, stakeReturn);
        }
        g._lockedStakeTotal -= st._stakedAmount;

        _stakeRemove(stakeListRef, stakeIndex);

        _globalsSync(g);

        return (
            stakeReturn,
            payout,
            penalty,
            cappedPenalty
        );
    }
 
    function fundRewards(
        uint128 amountPerDay,
        uint16 daysCount,
        uint16 shiftInDays
    )
        external
    {
        require(daysCount <= 365, "STAKING: too many days");

        stakingToken.safeTransferFrom(msg.sender, address(this), amountPerDay * daysCount);

        uint256 currentDay = _currentDay() + 1;
        uint256 fromDay = currentDay + shiftInDays;

        for (uint256 day = fromDay; day < fromDay + daysCount; day++) {
            dailyData[day].dayPayoutTotal += amountPerDay;
        }

        emit RewardsFund(amountPerDay, daysCount, shiftInDays);
    }

    /**
     * @dev PUBLIC FACING: Return the current stake count for a staker address
     * @param stakerAddr Address of staker
     */
    function stakeCount(address stakerAddr)
        external
        view
        returns (uint256)
    {
        return stakeLists[stakerAddr].length;
    }

    /**
     * @dev Open a stake.
     * @param g Cache of stored globals
     * @param newStakedAmount Amount of staking token to stake
     * @param newStakedDays Number of days to stake
     */
    function _stakeStart(
        GlobalsCache memory g,
        uint256 newStakedAmount,
        uint256 newStakedDays
    )
        internal
    {
        uint256 bonusShares = stakeStartBonusShares(newStakedAmount, newStakedDays);
        uint256 newStakeShares = (newStakedAmount + bonusShares) * SHARE_RATE_SCALE / g._shareRate;

        /* Ensure newStakedAmount is enough for at least one stake share */
        require(newStakeShares != 0, "STAKING: newStakedAmount must be at least minimum shareRate");

        /*
            The stakeStart timestamp will always be part-way through the current
            day, so it needs to be rounded-up to the next day to ensure all
            stakes align with the same fixed calendar days. The current day is
            already rounded-down, so rounded-up is current day + 1.
        */
        uint256 newLockedDay = g._currentDay + 1;

        /* Create Stake */
        uint40 newStakeId = ++g._latestStakeId;
        _stakeAdd(
            stakeLists[msg.sender],
            newStakeId,
            newStakedAmount,
            newStakeShares,
            newLockedDay,
            newStakedDays
        );

        emit StakeStart(
            msg.sender,
            newStakeId,
            uint40(block.timestamp),
            uint128(newStakedAmount),
            uint128(newStakeShares),
            uint16(newStakedDays)
        );

        /* Stake is added to total in the next round, not the current round */
        g._nextStakeSharesTotal += newStakeShares;

        /* Track total staked amount for inflation calculations */
        g._lockedStakeTotal += newStakedAmount;

        /* Remove his share from the pool when his stake ends */
        dailyData[newLockedDay + newStakedDays].sharesToBeRemoved += uint128(newStakeShares);
    }

    /* 
    Returns the same values as function stakeEnd. However, this function makes 
    it possible to anyone view the stakeReturn etc. for any staker. 

    The results can be obsolete if there are no daily updates.
    */
    function getStakeStatus(
        address staker, 
        uint256 stakeIndex, 
        uint40 stakeIdParam
    ) 
        external
        view
        returns (uint256 stakeReturn, uint256 payout, uint256 penalty, uint256 cappedPenalty)
    {
        GlobalsCache memory g;
        _globalsLoad(g);

        StakeStore[] storage stakeListRef = stakeLists[staker];

        require(stakeListRef.length != 0, "STAKING: Empty stake list");
        require(stakeIndex < stakeListRef.length, "STAKING: stakeIndex invalid");

        StakeCache memory st;
        _stakeLoad(stakeListRef[stakeIndex], stakeIdParam, st);

        require(g._currentDay >= st._lockedDay + HARD_LOCK_DAYS, "STAKING: hard lock period");

        uint256 servedDays = 0;
        bool prevUnlocked = (st._unlockedDay != 0);

        if (prevUnlocked) {
            servedDays = st._stakedDays;
        } else {
            st._unlockedDay = g._currentDay;

            servedDays = g._currentDay - st._lockedDay;
            if (servedDays > st._stakedDays) {
                servedDays = st._stakedDays;
            }
        }

        (stakeReturn, payout, penalty, cappedPenalty) = _stakePerformance(st, servedDays);
    }

    /**
     * @dev Calculates total stake payout including rewards for a multi-day range
     * @param stakeSharesParam Param from stake to calculate bonuses for
     * @param beginDay First day to calculate bonuses for
     * @param endDay Last day (non-inclusive) of range to calculate bonuses for
     * @return payout
     */
    function _calcPayoutRewards(
        uint256 stakeSharesParam,
        uint256 beginDay,
        uint256 endDay
    )
        private
        view
        returns (uint256 payout)
    {
        uint256 accRewardPerShare = dailyData[endDay - 1].accRewardPerShare - dailyData[beginDay - 1].accRewardPerShare;
        payout = stakeSharesParam * accRewardPerShare / ACC_REWARD_MULTIPLIER;
        return payout;
    }

    /**
     * @dev Calculate bonus shares for a new stake, if any
     * @param newStakedAmount Amount of staking token
     * @param newStakedDays Number of days to stake
     */
    function stakeStartBonusShares(uint256 newStakedAmount, uint256 newStakedDays)
        public
        pure
        returns (uint256 bonusShares)
    {
        uint256 cappedExtraDays = 0;

        /* Must be more than 1 day for Longer-Pays-Better */
        if (newStakedDays > 1) {
            cappedExtraDays = newStakedDays <= LPB_MAX_DAYS ? newStakedDays - 1 : LPB_MAX_DAYS;
        }

        uint256 cappedStakedAmount = newStakedAmount >= BPB_FROM_AMOUNT ? newStakedAmount - BPB_FROM_AMOUNT : 0;
        if (cappedStakedAmount > BPB_MAX) {
            cappedStakedAmount = BPB_MAX;
        }

        bonusShares = cappedExtraDays * BPB + cappedStakedAmount * LPB;
        bonusShares = newStakedAmount * bonusShares / (LPB * BPB);

        return bonusShares;
    }

    function _stakeUnlock(GlobalsCache memory g, StakeCache memory st)
        private
    {
        st._unlockedDay = g._currentDay;

        uint256 endDay = st._lockedDay + st._stakedDays;
        
        if (g._currentDay <= endDay) {
            dailyData[endDay].sharesToBeRemoved -= uint128(st._stakeShares);
            g._stakeSharesTotal -= st._stakeShares;
        }
    }

    function _stakePerformance(StakeCache memory st, uint256 servedDays)
        private
        view
        returns (uint256 stakeReturn, uint256 payout, uint256 penalty, uint256 cappedPenalty)
    {
        if (servedDays < st._stakedDays) {
            (payout, penalty) = _calcPayoutAndEarlyPenalty(
                st._lockedDay,
                st._stakedDays,
                servedDays,
                st._stakeShares
            );
            stakeReturn = st._stakedAmount + payout;
        } else {
            // servedDays must == stakedDays here
            payout = _calcPayoutRewards(
                st._stakeShares,
                st._lockedDay,
                st._lockedDay + servedDays
            );
            stakeReturn = st._stakedAmount + payout;

            penalty = _calcLatePenalty(st._lockedDay, st._stakedDays, st._unlockedDay, stakeReturn);
        }
        if (penalty != 0) {
            if (penalty > stakeReturn) {
                /* Cannot have a negative stake return */
                cappedPenalty = stakeReturn;
                stakeReturn = 0;
            } else {
                /* Remove penalty from the stake return */
                cappedPenalty = penalty;
                stakeReturn -= cappedPenalty;
            }
        }
        return (stakeReturn, payout, penalty, cappedPenalty);
    }

    function _calcPayoutAndEarlyPenalty(
        uint256 lockedDayParam,
        uint256 stakedDaysParam,
        uint256 servedDays,
        uint256 stakeSharesParam
    )
        private
        view
        returns (uint256 payout, uint256 penalty)
    {
        uint256 servedEndDay = lockedDayParam + servedDays;

        /* 50% of stakedDays (rounded up) with a minimum applied */
        uint256 penaltyDays = (stakedDaysParam + 1) / 2;
        if (penaltyDays < EARLY_PENALTY_MIN_DAYS) {
            penaltyDays = EARLY_PENALTY_MIN_DAYS;
        }

        if (penaltyDays < servedDays) {
            /*
                Simplified explanation of intervals where end-day is non-inclusive:

                penalty:    [lockedDay  ...  penaltyEndDay)
                delta:                      [penaltyEndDay  ...  servedEndDay)
                payout:     [lockedDay  .......................  servedEndDay)
            */
            uint256 penaltyEndDay = lockedDayParam + penaltyDays;
            penalty = _calcPayoutRewards(stakeSharesParam, lockedDayParam, penaltyEndDay);

            uint256 delta = _calcPayoutRewards(stakeSharesParam, penaltyEndDay, servedEndDay);
            payout = penalty + delta;
            return (payout, penalty);
        }

        /* penaltyDays >= servedDays  */
        payout = _calcPayoutRewards(stakeSharesParam, lockedDayParam, servedEndDay);

        if (penaltyDays == servedDays) {
            penalty = payout;
        } else {
            /*
                (penaltyDays > servedDays) means not enough days served, so fill the
                penalty days with the average payout from only the days that were served.
            */
            penalty = payout * penaltyDays / servedDays;
        }
        return (payout, penalty);
    }

    function _calcLatePenalty(
        uint256 lockedDayParam,
        uint256 stakedDaysParam,
        uint256 unlockedDayParam,
        uint256 rawStakeReturn
    )
        private
        pure
        returns (uint256)
    {
        /* Allow grace time before penalties accrue */
        uint256 maxUnlockedDay = lockedDayParam + stakedDaysParam + LATE_PENALTY_GRACE_DAYS;
        if (unlockedDayParam <= maxUnlockedDay) {
            return 0;
        }

        /* Calculate penalty as a percentage of stake return based on time */
        return rawStakeReturn * (unlockedDayParam - maxUnlockedDay) / LATE_PENALTY_SCALE_DAYS;
    }

    function _splitPenaltyProceeds(GlobalsCache memory g, uint256 penalty)
        private
    {
        /* Split a penalty 50:50 between (Origin + burn) and stakePenaltyTotal */
        uint256 splitPenalty = penalty / 2;

        if (splitPenalty != 0) {
            //30% of the total penalty is sent to origin address
            uint256 originPenalty = splitPenalty * 3 / 5;
            stakingToken.safeTransfer(originAddr, originPenalty);

            //20% of the total penalty is burned
            stakingToken.burn(splitPenalty - originPenalty);
        }

        /* Use the other half of the penalty to account for an odd-numbered penalty */
        splitPenalty = penalty - splitPenalty;
        g._stakePenaltyTotal += splitPenalty;
    }

    function _shareRateUpdate(GlobalsCache memory g, StakeCache memory st, uint256 stakeReturn)
        private
    {
        if (stakeReturn > st._stakedAmount) {
            /*
                Calculate the new shareRate that would yield the same number of shares if
                the user re-staked this stakeReturn, factoring in any bonuses they would
                receive in stakeStart().
            */
            uint256 bonusShares = stakeStartBonusShares(stakeReturn, st._stakedDays);
            uint256 newShareRate = (stakeReturn + bonusShares) * SHARE_RATE_SCALE / st._stakeShares;

            if (newShareRate > SHARE_RATE_MAX) {
                /*
                    Realistically this can't happen, but there are contrived theoretical
                    scenarios that can lead to extreme values of newShareRate, so it is
                    capped to prevent them anyway.
                */
                newShareRate = SHARE_RATE_MAX;
            }

            if (newShareRate > g._shareRate) {
                g._shareRate = newShareRate;

                emit ShareRateChange(
                    st._stakeId,
                    uint40(block.timestamp),
                    uint40(newShareRate)
                );
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./helpers/IERC20Burnable.sol";

abstract contract GlobalsAndUtility {
    event DailyDataUpdate(
        address indexed updaterAddr,
        uint40 timestamp,
        uint16 beginDay,
        uint16 endDay,
        bool isAutoUpdate
    );

    event StakeStart(
        address indexed stakerAddr,
        uint40 indexed stakeId,
        uint40 timestamp,
        uint128 stakedAmount,
        uint128 stakeShares,
        uint16 stakedDays
    );

    event StakeGoodAccounting(        
        address indexed stakerAddr,
        uint40 indexed stakeId,
        address indexed senderAddr,
        uint40 timestamp,
        uint128 stakedAmount,
        uint128 stakeShares,
        uint128 payout,
        uint128 penalty
    );

    event StakeEnd(
        address indexed stakerAddr,
        uint40 indexed stakeId,
        uint40 timestamp,
        uint128 stakedAmount,
        uint128 stakeShares,
        uint128 payout,
        uint128 penalty,
        uint16 servedDays,
        bool prevUnlocked
    );

    event ShareRateChange(
        uint40 indexed stakeId,
        uint40 timestamp,
        uint40 shareRate
    );

    event RewardsFund(
        uint128 amountPerDay,
        uint16 daysCount,
        uint16 shiftInDays
    );

    IERC20Burnable public stakingToken;
    uint40 public launchTime;
    address public originAddr;

    uint256 internal constant ACC_REWARD_MULTIPLIER = 1e36;
    uint256 internal constant TOKEN_DECIMALS = 18;

    /* Stake timing parameters */
    uint256 internal constant HARD_LOCK_DAYS = 15;
    uint256 internal constant MIN_STAKE_DAYS = 30;
    uint256 internal constant MAX_STAKE_DAYS = 1095;
    uint256 internal constant EARLY_PENALTY_MIN_DAYS = 30;
    uint256 internal constant LATE_PENALTY_GRACE_DAYS = 30;
    uint256 internal constant LATE_PENALTY_SCALE_DAYS = 100;

    /* Stake shares Longer Pays Better bonus constants used by _stakeStartBonusShares() */
    uint256 private constant LPB_BONUS_PERCENT = 600;
    uint256 private constant LPB_BONUS_MAX_PERCENT = 1800;
    uint256 internal constant LPB = 364 * 100 / LPB_BONUS_PERCENT;
    uint256 internal constant LPB_MAX_DAYS = LPB * LPB_BONUS_MAX_PERCENT / 100;

    /* Stake shares Bigger Pays Better bonus constants used by _stakeStartBonusShares() */
    uint256 private constant BPB_BONUS_PERCENT = 50;
    uint256 internal constant BPB_MAX = 1e6 * 10 ** TOKEN_DECIMALS;
    uint256 internal constant BPB = BPB_MAX * 100 / BPB_BONUS_PERCENT;
    uint256 internal constant BPB_FROM_AMOUNT = 50000 * 10 ** TOKEN_DECIMALS;

    /* Share rate is scaled to increase precision */
    uint256 internal constant SHARE_RATE_SCALE = 1e5;

    /* Share rate max (after scaling) */
    uint256 internal constant SHARE_RATE_UINT_SIZE = 40;
    uint256 internal constant SHARE_RATE_MAX = (1 << SHARE_RATE_UINT_SIZE) - 1;

    /* Globals expanded for memory (except _latestStakeId) and compact for storage */
    struct GlobalsCache {
        uint256 _lockedStakeTotal;
        uint256 _nextStakeSharesTotal;

        uint256 _stakePenaltyTotal;
        uint256 _stakeSharesTotal;

        uint40 _latestStakeId;
        uint256 _shareRate;
        uint256 _dailyDataCount;

        uint256 _currentDay;
    }

    struct GlobalsStore {
        uint128 lockedStakeTotal;
        uint128 nextStakeSharesTotal;

        uint128 stakePenaltyTotal;
        uint128 stakeSharesTotal;

        uint40 latestStakeId;
        uint40 shareRate;
        uint16 dailyDataCount;
    }

    GlobalsStore public globals;

    /* Daily data */
    struct DailyDataStore {
        uint128 dayPayoutTotal;
        uint128 sharesToBeRemoved;
        uint256 accRewardPerShare;
    }

    mapping(uint256 => DailyDataStore) public dailyData;

    /* Stake expanded for memory (except _stakeId) and compact for storage */
    struct StakeCache {
        uint256 _stakedAmount;
        uint256 _stakeShares;
        uint40 _stakeId;
        uint256 _lockedDay;
        uint256 _stakedDays;
        uint256 _unlockedDay;
    }

    struct StakeStore {
        uint128 stakedAmount;
        uint128 stakeShares;
        uint40 stakeId;
        uint16 lockedDay;
        uint16 stakedDays;
        uint16 unlockedDay;
    }

    mapping(address => StakeStore[]) public stakeLists;

    /* Temporary state for calculating daily rounds */
    struct DailyRoundState {
        uint256 _payoutTotal;
        uint256 _accRewardPerShare;
    }

    /**
     * @dev PUBLIC FACING: Optionally update daily data for a smaller
     * range to reduce gas cost for a subsequent operation
     * @param beforeDay Only update days before this day number (optional; 0 for current day)
     */
    function dailyDataUpdate(uint256 beforeDay)
        external
    {
        GlobalsCache memory g;
        _globalsLoad(g);

        if (beforeDay != 0) {
            require(beforeDay <= g._currentDay, "STAKING: beforeDay cannot be in the future");

            _dailyDataUpdate(g, beforeDay, false);
        } else {
            /* Default to updating before current day */
            _dailyDataUpdate(g, g._currentDay, false);
        }

        _globalsSync(g);
    }

    /**
     * @dev PUBLIC FACING: External helper to return multiple values of daily data with
     * a single call. Ugly implementation due to limitations of the standard ABI encoder.
     * @param beginDay First day of data range
     * @param endDay Last day (non-inclusive) of data range
     * @return listDayAccRewardPerShare and listDayPayoutTotal
     */
    function dailyDataRange(uint256 beginDay, uint256 endDay)
        external
        view
        returns (uint256[] memory listDayAccRewardPerShare, uint256[] memory listDayPayoutTotal)
    {
        require(beginDay < endDay, "STAKING: range invalid");

        listDayAccRewardPerShare = new uint256[](endDay - beginDay);
        listDayPayoutTotal = new uint256[](endDay - beginDay);

        uint256 src = beginDay;
        uint256 dst = 0;
        do {
            listDayAccRewardPerShare[dst] = dailyData[src].accRewardPerShare;
            listDayPayoutTotal[dst++] = dailyData[src].dayPayoutTotal;
        } while (++src < endDay);
    }

    /**
     * @dev PUBLIC FACING: External helper to return most global info with a single call.
     * @return global variables
     */
    function globalInfo()
        external
        view
        returns (GlobalsCache memory)
    {
        GlobalsCache memory g;
        _globalsLoad(g);

        return g;
    }

    /**
     * @dev PUBLIC FACING: External helper for the current day number since launch time
     * @return Current day number (zero-based)
     */
    function currentDay()
        external
        view
        returns (uint256)
    {
        return _currentDay();
    }

    function _currentDay()
        internal
        view
        returns (uint256)
    {
        return (block.timestamp - launchTime) / 1 days;
    }

    function _dailyDataUpdateAuto(GlobalsCache memory g)
        internal
    {
        _dailyDataUpdate(g, g._currentDay, true);
    }

    function _globalsLoad(GlobalsCache memory g)
        internal
        view
    {
        g._lockedStakeTotal = globals.lockedStakeTotal;
        g._nextStakeSharesTotal = globals.nextStakeSharesTotal;

        g._stakeSharesTotal = globals.stakeSharesTotal;
        g._stakePenaltyTotal = globals.stakePenaltyTotal;

        g._latestStakeId = globals.latestStakeId;
        g._shareRate = globals.shareRate;
        g._dailyDataCount = globals.dailyDataCount;
        
        g._currentDay = _currentDay();
    }

    function _globalsSync(GlobalsCache memory g)
        internal
    {
        globals.lockedStakeTotal = uint128(g._lockedStakeTotal);
        globals.nextStakeSharesTotal = uint128(g._nextStakeSharesTotal);

        globals.stakeSharesTotal = uint128(g._stakeSharesTotal);
        globals.stakePenaltyTotal = uint128(g._stakePenaltyTotal);

        globals.latestStakeId = g._latestStakeId;
        globals.shareRate = uint40(g._shareRate);
        globals.dailyDataCount = uint16(g._dailyDataCount);
    }

    function _stakeLoad(StakeStore storage stRef, uint40 stakeIdParam, StakeCache memory st)
        internal
        view
    {
        /* Ensure caller's stakeIndex is still current */
        require(stakeIdParam == stRef.stakeId, "STAKING: stakeIdParam not in stake");

        st._stakedAmount = stRef.stakedAmount;
        st._stakeShares = stRef.stakeShares;
        st._stakeId = stRef.stakeId;
        st._lockedDay = stRef.lockedDay;
        st._stakedDays = stRef.stakedDays;
        st._unlockedDay = stRef.unlockedDay;
    }

    function _stakeUpdate(StakeStore storage stRef, StakeCache memory st)
        internal
    {
        stRef.stakedAmount = uint128(st._stakedAmount);
        stRef.stakeShares = uint128(st._stakeShares);
        stRef.stakeId = st._stakeId;
        stRef.lockedDay = uint16(st._lockedDay);
        stRef.stakedDays = uint16(st._stakedDays);
        stRef.unlockedDay = uint16(st._unlockedDay);
    }

    function _stakeAdd(
        StakeStore[] storage stakeListRef,
        uint40 newStakeId,
        uint256 newstakedAmount,
        uint256 newStakeShares,
        uint256 newLockedDay,
        uint256 newStakedDays
    )
        internal
    {
        stakeListRef.push(
            StakeStore(
                uint128(newstakedAmount),
                uint128(newStakeShares),
                newStakeId,
                uint16(newLockedDay),
                uint16(newStakedDays),
                uint16(0) // unlockedDay
            )
        );
    }

    /**
     * @dev Efficiently delete from an unordered array by moving the last element
     * to the "hole" and reducing the array length. Can change the order of the list
     * and invalidate previously held indexes.
     * @notice stakeListRef length and stakeIndex are already ensured valid in stakeEnd()
     * @param stakeListRef Reference to stakeLists[stakerAddr] array in storage
     * @param stakeIndex Index of the element to delete
     */
    function _stakeRemove(StakeStore[] storage stakeListRef, uint256 stakeIndex)
        internal
    {
        uint256 lastIndex = stakeListRef.length - 1;

        /* Skip the copy if element to be removed is already the last element */
        if (stakeIndex != lastIndex) {
            /* Copy last element to the requested element's "hole" */
            stakeListRef[stakeIndex] = stakeListRef[lastIndex];
        }

        stakeListRef.pop();
    }

    function _dailyRoundCalc(GlobalsCache memory g, DailyRoundState memory rs, uint256 day)
        private
        view
    {
        rs._payoutTotal = dailyData[day].dayPayoutTotal;
        rs._accRewardPerShare = day == 0 ? 0 : dailyData[day - 1].accRewardPerShare;

        if (g._stakePenaltyTotal != 0) {
            rs._payoutTotal += g._stakePenaltyTotal;
            g._stakePenaltyTotal = 0;
        }

        if (g._stakeSharesTotal > 0) {
            rs._accRewardPerShare += rs._payoutTotal * ACC_REWARD_MULTIPLIER / g._stakeSharesTotal;
        }
    }

    function _dailyRoundCalcAndStore(GlobalsCache memory g, DailyRoundState memory rs, uint256 day)
        private
    {
        g._stakeSharesTotal -= dailyData[day].sharesToBeRemoved;

        _dailyRoundCalc(g, rs, day);

        dailyData[day].accRewardPerShare = rs._accRewardPerShare;

        if (g._stakeSharesTotal > 0) {
            dailyData[day].dayPayoutTotal = uint128(rs._payoutTotal);
        } else {
            // nobody staking that day, move the reward to the next day if any
            dailyData[day + 1].dayPayoutTotal += uint128(rs._payoutTotal);
        }
    }

    function _dailyDataUpdate(GlobalsCache memory g, uint256 beforeDay, bool isAutoUpdate)
        private
    {
        if (g._dailyDataCount >= beforeDay) {
            /* Already up-to-date */
            return;
        }

        DailyRoundState memory rs;

        uint256 day = g._dailyDataCount;

        _dailyRoundCalcAndStore(g, rs, day);

        /* Stakes started during this day are added to the total the next day */
        if (g._nextStakeSharesTotal != 0) {
            g._stakeSharesTotal += g._nextStakeSharesTotal;
            g._nextStakeSharesTotal = 0;
        }

        while (++day < beforeDay) {
            _dailyRoundCalcAndStore(g, rs, day);
        }

        emit DailyDataUpdate(
            msg.sender,
            uint40(block.timestamp),
            uint16(g._dailyDataCount),
            uint16(day),
            isAutoUpdate
        );

        g._dailyDataCount = day;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20Burnable is IERC20 {
    function burn(uint256 amount) external;
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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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