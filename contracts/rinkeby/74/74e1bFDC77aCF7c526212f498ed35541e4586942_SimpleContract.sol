pragma solidity ^0.8.0;

contract SimpleContract{
  string name;
  uint256 value;

  function setName(string memory _name) public {
    name = _name;
  }

  function setValue(uint256 _value) public {
    value = _value;
  }

}