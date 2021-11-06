/**
 *Submitted for verification at Etherscan.io on 2021-11-06
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface KeeperCompatibleInterface {
    function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);
    function performUpkeep(bytes calldata performData) external;
}

contract Counter is KeeperCompatibleInterface {

    uint public counter;    // Public counter variable

    // Use an interval in seconds and a timestamp to slow execution of Upkeep
    uint public immutable interval;
    uint public lastTimeStamp;
    address public keeperRegistery;
    
    modifier onlyKeeper {
      require(msg.sender == keeperRegistery, "Invalid access");
      _;
    }

    
    constructor(uint updateInterval, address keeperRegistery_) {
      interval = updateInterval;
      keeperRegistery = keeperRegistery_;
      lastTimeStamp = block.timestamp;
      counter = 0;
    }

    function checkUpkeep(bytes calldata checkData) external view override returns (bool upkeepNeeded, bytes memory performData) {
        upkeepNeeded = (block.timestamp - lastTimeStamp) > interval;
        performData = checkData;
    }

    function performUpkeep(bytes calldata performData) external override onlyKeeper {
        lastTimeStamp = block.timestamp;
        counter = counter + 1;
        performData;
    }
}