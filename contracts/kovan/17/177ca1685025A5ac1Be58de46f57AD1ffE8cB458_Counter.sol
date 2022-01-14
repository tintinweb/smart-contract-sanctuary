pragma solidity ^0.8.0;

contract Counter {
  uint256 count;  // persistent contract storage

  constructor() {
    count = 100;   
  }
  
  function increment() public {
      count += 1;
  }

  function updateCount(uint256 _count) public {
      count = _count;
  }

  function getCount() public view returns (uint256) {
      return count;
  }
}