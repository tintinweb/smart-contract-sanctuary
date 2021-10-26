/**
 *Submitted for verification at BscScan.com on 2021-10-26
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

/**
 * @notice A sample upkeep contract that emits event at regular intervals
 */

contract TimedUpKeep {
  uint public lastBlockServiced; 
  uint public blocksInterval = 50;
  
  event timedAlarm(uint);

  function checkUpkeep(bytes calldata data) external view returns (bool, bytes memory) {
    
    //check if set number of blocks have passed
    bool shouldPerformUpkeep = (block.number-lastBlockServiced) > blocksInterval;
    
    return (shouldPerformUpkeep, "");
  }
  

  function performUpkeep(bytes calldata data) external {
        
      lastBlockServiced = block.number;
      emit timedAlarm(lastBlockServiced);
      //do something useful here
  }
  
 function debugVars() external view returns (uint,uint,uint){
      
      return(lastBlockServiced,blocksInterval,block.number);
  }
  
  function comingAfter() external view returns (uint)
  {
      return blocksInterval-(block.number-lastBlockServiced);
  }
  
    function setBlocksInterval(uint interval) public {
    blocksInterval = interval;
  }
  
}