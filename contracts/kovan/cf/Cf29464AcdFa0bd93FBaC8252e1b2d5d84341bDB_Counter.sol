/**
 *Submitted for verification at Etherscan.io on 2021-11-13
*/

pragma solidity >=0.4.22 <0.9.0;


// SPDX-License-Identifier: MIT
interface KeeperCompatibleInterface {
    function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);
    function performUpkeep(bytes calldata performData) external;
}

contract Counter is KeeperCompatibleInterface {

    uint public counter;    // Public counter variable

    // Use an interval in seconds and a timestamp to slow execution of Upkeep
    uint public immutable interval;
    uint public lastTimeStamp;    

    constructor(uint _interval) {
      interval = _interval;
      lastTimeStamp = block.timestamp;
      counter = 0;
    }

    function checkUpkeep(bytes calldata checkData) external view override returns (bool upkeepNeeded, bytes memory performData) {
        upkeepNeeded = (block.timestamp - lastTimeStamp) > interval;
        performData = checkData;
    }

    function performUpkeep(bytes calldata performData) external override {
        lastTimeStamp = block.timestamp;
        counter = counter + 1;
        performData;
    }
}