/**
 *Submitted for verification at hooscan.com on 2021-07-01
*/

pragma solidity ^0.5.16;


contract GoblinEvent {

  address public owner;
  event NewGoblin(address newGoblin);
  
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
  
  function addNewGoblin(address goblin) external onlyOwner {
     emit NewGoblin(goblin);
  }
}