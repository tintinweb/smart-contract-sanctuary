/**
 *Submitted for verification at hooscan.com on 2021-07-28
*/

pragma solidity ^0.5.16;

contract StakingEvent {

  address public owner;
  event NewStaking(address staking);
  
  constructor() public {
    owner = msg.sender;
  }

  modifier onlyOwner {
        require(msg.sender == owner, "Only the contract owner may perform this action");
        _;
  }

  function setOwner(address newOwner) external onlyOwner {
    owner = newOwner;
  }
  
  function addNewStaking(address goblin) external onlyOwner {
     emit NewStaking(goblin);
  }
}