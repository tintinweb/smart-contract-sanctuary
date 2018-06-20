pragma solidity ^0.4.23;

contract StoreValue {
  address public owner;
  string public storedValue;

  constructor() public {
    owner = msg.sender;
  }

  modifier restricted() {
    if (msg.sender == owner) _;
  }

  function setValue(string completed) public restricted {
    storedValue = completed;
  }

  function getValue() public view returns (string) {
    return storedValue;
  }
}