pragma solidity ^0.4.13;

contract DappTutorial {
  uint storedData;

  function set(uint x) {
    storedData = x;
  }

  function get() constant returns (uint) {
    return storedData * 2;
  }
}