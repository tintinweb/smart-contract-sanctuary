pragma solidity ^0.8.0;

contract Counter {
  uint public counter;

  function updateCounter(uint _counter) external {
    counter = _counter;
  }

  function readCounter() external view returns(uint) {
    return counter;
  }
}