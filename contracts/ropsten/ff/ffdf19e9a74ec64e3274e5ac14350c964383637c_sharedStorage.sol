pragma solidity ^0.4.19;

contract sharedStorage { 
  uint dataStorage; 
  
  // Sets dataStorage value
  function set(uint x) public { 
    dataStorage = x;
  }

  // Read dataStorage value
  function read() public constant returns (uint) { 
    return dataStorage;
  }
}