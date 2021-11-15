// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

struct ReleaseSchedule {
    uint releaseCount;
    uint delayUntilFirstReleaseInSeconds;
    uint initialReleasePortionInBips;
    uint periodBetweenReleasesInSeconds;
}

struct Timelock {
    uint scheduleId;
    uint commencementTimestamp;
    uint tokensTransferred;
    uint totalAmount;
}

library ScheduleCalc {
    uint constant BIPS_PRECISION = 10000;

    function calculateUnlocked(uint commencedTimestamp, uint currentTimestamp, uint amount, ReleaseSchedule memory releaseSchedule) external pure returns (uint unlocked) {
        if(commencedTimestamp > currentTimestamp) {
            return 0;
        }
        uint secondsElapsed = currentTimestamp - commencedTimestamp;

        // return the full amount if the total lockup period has expired
        // unlocked amounts in each period are truncated and round down remainders smaller than the smallest unit
        // unlocking the full amount unlocks any remainder amounts in the final unlock period
        // this is done first to reduce computation
        if (secondsElapsed >= releaseSchedule.delayUntilFirstReleaseInSeconds +
        (releaseSchedule.periodBetweenReleasesInSeconds * (releaseSchedule.releaseCount - 1))) {
            return amount;
        }

        // unlock the initial release if the delay has elapsed
        if (secondsElapsed >= releaseSchedule.delayUntilFirstReleaseInSeconds) {
            unlocked = (amount * releaseSchedule.initialReleasePortionInBips) / BIPS_PRECISION;

            // if at least one period after the delay has passed
            if (secondsElapsed - releaseSchedule.delayUntilFirstReleaseInSeconds
                >= releaseSchedule.periodBetweenReleasesInSeconds) {

                // calculate the number of additional periods that have passed (not including the initial release)
                // this discards any remainders (ie it truncates / rounds down)
                uint additionalUnlockedPeriods =
                (secondsElapsed - releaseSchedule.delayUntilFirstReleaseInSeconds) /
                releaseSchedule.periodBetweenReleasesInSeconds;

                // calculate the amount of unlocked tokens for the additionalUnlockedPeriods
                // multiplication is applied before division to delay truncating to the smallest unit
                // this distributes unlocked tokens more evenly across unlock periods
                // than truncated division followed by multiplication
                unlocked += ((amount - unlocked) * additionalUnlockedPeriods) / (releaseSchedule.releaseCount - 1);
            }
        }

        return unlocked;
    }
}

