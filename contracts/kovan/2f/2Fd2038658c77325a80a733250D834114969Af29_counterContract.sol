/**
 *Submitted for verification at Etherscan.io on 2021-10-26
*/

pragma solidity ^0.8.0;

interface KeeperCompatibleInterface {

  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded,bytes memory performData);
  
  function performUpkeep(bytes calldata performData) external;
    
}


contract counterContract is KeeperCompatibleInterface {
  
    //counter variable
    uint public counter;
    
    //function to test your counter
    function increaseCounter() public {
        counter += 1;
    }
    
    //used to view the current block.timestamp
    function timeStamp() public view returns (uint) {
        return block.timestamp;
    }

    // check to see if the block.timestamp is divisible by 7
    // if true call the performUpkeep function
    function checkUpkeep(bytes calldata /* checkData */) external override returns (bool upkeepNeeded, bytes memory /* performData */) {
        upkeepNeeded = (block.timestamp % 7 == 0);
    }
    //if the block.timestamp is divisible by 7 increase the counter (function checkUpkeep above)
    //keeper will perform update
    function performUpkeep(bytes calldata /* performData */) external override {
        counter = counter + 1;
    }
}