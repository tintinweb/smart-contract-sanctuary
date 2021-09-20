/**
 *Submitted for verification at Etherscan.io on 2021-09-20
*/

pragma solidity 0.8.7;

interface KeeperCompatibleInterface {
    function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);
    function performUpkeep(bytes calldata performData) external;
}


contract OusdKeeper is KeeperCompatibleInterface {
    struct Config {
        uint24 windowStart;
        uint24 windowEnd;
    }
    address constant vault = 0xE75D77B1865Ae93c7eaa3040B038D7aA7BC02F70;
    uint24 immutable windowStart; // seconds after start of day
    uint24 immutable windowEnd; // seconds after start of day
    uint256 lastRunDay = 0;

    constructor(
        uint24 _windowStart,
        uint24 _windowEnd
    ) {
        windowStart = _windowStart;
        windowEnd = _windowEnd;
    }

    function checkUpkeep(bytes calldata checkData)
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        // If either can run, let's go!
        (bool runRebase, bool runAllocate) = _shouldRun(checkData);
        upkeepNeeded = (runRebase || runAllocate);
        performData = checkData;
    }

    function performUpkeep(bytes calldata performData) external override {
        (bool runRebase, bool runAllocate) = _shouldRun(performData);
        if (runRebase || runAllocate) {
            // write today, so that we only run once per day
            lastRunDay = (block.timestamp / 86400);
        }
        
        // Allocate before rebase, so the rebase picks up the harvested rewards.
        // 
        // Both commands run and do not revert if they fail so that the last run
        // day is still written the keepers do empty their gas running the
        // failing method over and over again.

        if (runAllocate) {
            vault.call(abi.encodeWithSignature("allocate()"));
        }
        if (runRebase) {
            vault.call(abi.encodeWithSignature("rebase()"));
        }
    }

    function _shouldRun(bytes memory performData)
        internal
        view
        returns (bool runRebase, bool runAllocate)
    {
        // Have we run today?
        uint256 day = block.timestamp / 86400;
        if (lastRunDay >= day) {
            return (false, false);
        }

        // Are we in the window?
        uint256 daySeconds = block.timestamp % 86400;
        if (daySeconds < windowStart || daySeconds > windowEnd) {
            return (false, false);
        }

        // Load schedule
        require(performData.length == 2, "Wrong schedule format");
        uint8 rebaseDays = uint8(performData[0]); // day of week bits
        uint8 allocateDays = uint8(performData[1]); // day of week bits

        // Weekday
        uint8 weekday = uint8((day + 4) % 7);
        // Need a rebase?
        if (((rebaseDays >> weekday) & 1) != 0) {
            runRebase = true;
        }
        // Need an allocate?
        if (((allocateDays >> weekday) & 1) != 0) {
            runAllocate = true;
        }
    }
}