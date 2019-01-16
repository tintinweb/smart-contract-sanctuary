pragma solidity ^0.4.24;

contract CounterContract {
  uint public counter;
  function increment() public {
    counter = counter + 1;
  }
}