/**
 *Submitted for verification at Etherscan.io on 2021-09-09
*/

pragma solidity 0.8.7;

interface KeeperCompatibleInterface {
    function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);
    function performUpkeep(bytes calldata performData) external;
}

interface Vault {
    function allocate() external;
    function rebase() external;
}

contract OusdKeeper is KeeperCompatibleInterface {
    struct Config {
        uint8 rebaseDays;
        uint8 allocateDays;
        uint24 windowStart;
        uint24 windowEnd;
    }
    Vault constant vault = Vault(0xE75D77B1865Ae93c7eaa3040B038D7aA7BC02F70);
    uint8 immutable rebaseDays; // day of week bits
    uint8 immutable allocateDays; // day of week bits
    uint24 immutable windowStart; // seconds after start of day
    uint24 immutable windowEnd; // seconds after start of day
    uint256 lastRunDay = 0;

    constructor(
        uint8 _rebaseDays,
        uint8 _allocateDays,
        uint24 _windowStart,
        uint24 _windowEnd
    ) {
        rebaseDays = _rebaseDays;
        allocateDays = _allocateDays;
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
        (bool runRebase, bool runAllocate) = _shouldRun();
        upkeepNeeded = (runRebase || runAllocate);
    }

    function performUpkeep(bytes calldata performData) external override {
        (bool runRebase, bool runAllocate) = _shouldRun();
        if (runRebase || runAllocate) {
            // write today, so that we only run once per day
            lastRunDay = (block.timestamp / 86400);
        }
        // allocate before rebase, so the rebase picks up the harvested rewards
        if (runAllocate) {
            vault.allocate();
        }
        if (runRebase) {
            vault.rebase();
        }
    }

    function _shouldRun()
        internal
        view
        returns (bool runRebase, bool runAllocate)
    {
        // // Have we run today?
        uint256 day = block.timestamp / 86400;
        if (lastRunDay >= day) {
            return (false, false);
        }

        // // Are we in the window?
        uint256 daySeconds = block.timestamp % 86400;
        if (daySeconds < windowStart || daySeconds > windowEnd) {
            return (false, false);
        }

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