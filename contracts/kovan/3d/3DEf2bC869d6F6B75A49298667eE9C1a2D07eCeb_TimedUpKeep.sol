/**
 *Submitted for verification at Etherscan.io on 2021-04-08
*/

pragma solidity 0.7.6;

contract TimedUpKeep {
  uint public lastBlockServiced; 
  uint public blocksInterval = 5;
  
  event timedAlarm(uint);


  function setBlocksInterval(uint interval) public {
    blocksInterval = interval;
  }

  function checkUpkeep(bytes calldata data) external view returns (bool, bytes memory) {
    
    //check if set number of blocks have passed
    bool shouldPerformUpkeep = block.number-lastBlockServiced >= blocksInterval;
    
    return (shouldPerformUpkeep, "");
  }
  
  function debugVars() external view returns (uint,uint,uint){
      
      return(lastBlockServiced,blocksInterval,block.number);
  }
  
  function comingAfter() external view returns (uint)
  {
      return blocksInterval-(block.number-lastBlockServiced);
  }

  function performUpkeep(bytes calldata data) external {
       
      lastBlockServiced = block.number;
      emit timedAlarm(lastBlockServiced);
      //do something useful here
  }
}