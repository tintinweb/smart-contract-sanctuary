/**
 *Submitted for verification at Etherscan.io on 2021-06-28
*/

// SPDX-License-Identifier:MIT
pragma solidity ^0.6.7;

interface IKeeper {
    function rebase() external;
    function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, uint untilKeepNeeded, bytes memory performData);
    function performUpkeep(bytes calldata performData) external;
}

contract RebaseKeepV2 is IKeeper {
    uint public rebaseCount;

    uint public immutable interval = 5; //immutable = const across the whole lifetime of contract!
    uint public lastTimeStamp;

    constructor() public {
        lastTimeStamp = block.timestamp;
        rebaseCount = 0;
    }

    function rebase() external override {
        rebaseCount += 1;
    }

    function checkUpkeep(bytes calldata checkData) external override returns (bool upkeepNeeded, uint untilKeepNeeded, bytes memory performData) {
        untilKeepNeeded = block.timestamp - lastTimeStamp;
        upkeepNeeded = untilKeepNeeded > interval;
        performData = checkData;
    }

    function performUpkeep(bytes calldata performData) external override {
        lastTimeStamp = block.timestamp;
        this.rebase();
        performData;
    }
    
}