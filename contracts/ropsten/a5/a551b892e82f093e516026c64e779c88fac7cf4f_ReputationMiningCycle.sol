pragma solidity ^0.4.23;
contract ReputationMiningCycle {
    function getReputationUpdateLogEntry(uint256 _id) public view 
    returns (address, int256, uint256, address, uint256, uint256) {
    
    return (msg.sender, 3, 1, msg.sender, 4, _id);
  }
}