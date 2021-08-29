/**
 *Submitted for verification at Etherscan.io on 2021-08-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface KeeperCompatibleInterface {
  /**
   * @notice checks if the contract requires work to be done.
   * @param checkData data passed to the contract when checking for upkeep.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with,
   * if upkeep is needed.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded,bytes memory performData);
  
  /**
   * @notice Performs work on the contract. Executed by the keepers, via the registry.
   * @param performData is the data which was passed back from the checkData
   * simulation.
   */
  function performUpkeep(bytes calldata performData) external;
    
}



contract counterContract is KeeperCompatibleInterface {
  
    //counter variable
    uint public counter;
    
    //function to test your counter
    function increaseCounter() public {
        counter += 1;
    }
    
    //used to view the current block timeStamp
    function timeStamp() public view returns (uint) {
        return block.timestamp;
    }

    // chack to see if the block.timestamp is divisible by 7?
    // if ture call performUpkeep
    function checkUpkeep(bytes calldata /* checkData */) external override returns (bool upkeepNeeded, bytes memory /* performData */) {
        upkeepNeeded = (block.timestamp % 7 == 0);
    }
    //if the block.timestamp is divisible by 7 increase the counter
    function performUpkeep(bytes calldata /* performData */) external override {
        counter = counter + 1;
    }
}