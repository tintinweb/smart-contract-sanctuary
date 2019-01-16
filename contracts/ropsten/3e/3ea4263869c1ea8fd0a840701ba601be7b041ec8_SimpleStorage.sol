pragma solidity ^0.4.18;

contract SimpleStorage {
  uint storedData;

  event ValueChanged(uint value);

  function set(uint x) public {
    storedData = x;
    ValueChanged(x);
  }

  function get() public view returns (uint) {
    return storedData;
  }
}