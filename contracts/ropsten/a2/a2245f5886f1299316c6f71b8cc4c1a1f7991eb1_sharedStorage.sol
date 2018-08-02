pragma solidity ^0.4.19;

contract sharedStorage { 
  uint dataStorage; 
  address owner = msg.sender;
  
  modifier onlyOwner{
    require(msg.sender == owner);
    _;
  }
  
  // Set dataStorage value
  function store(uint x) public onlyOwner{ 
    dataStorage = x;
  }

  // Read dataStorage value
  function read() public constant returns (uint) { 
    return dataStorage;
  }
}