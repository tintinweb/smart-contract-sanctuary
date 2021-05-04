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
    function calculateUnlocked(uint commencedTimestamp, uint currentTimestamp, uint amount, ReleaseSchedule memory releaseSchedule) public pure returns (uint unlocked) {
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
            unlocked += (amount * releaseSchedule.initialReleasePortionInBips) / 1e4;

            // if at least one period after the delay has passed
            if (secondsElapsed - releaseSchedule.delayUntilFirstReleaseInSeconds
                >= releaseSchedule.periodBetweenReleasesInSeconds) {

                // calculate the number of additional periods that have passed (not including the initial release)
                // this discards any remainders (ie it truncates / rounds down)
                uint additionalPeriods =
                (secondsElapsed - releaseSchedule.delayUntilFirstReleaseInSeconds) /
                releaseSchedule.periodBetweenReleasesInSeconds;

                // unlocked includes the number of additionalPeriods elapsed, times the evenly distributed remaining amount
                unlocked += additionalPeriods * ((amount - unlocked) / (releaseSchedule.releaseCount - 1));
            }
        }

        return unlocked;
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 1000
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}