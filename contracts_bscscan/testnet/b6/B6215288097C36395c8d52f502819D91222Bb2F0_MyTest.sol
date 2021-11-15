pragma solidity 0.8.0;

contract MyTest {
  uint value;

  function setValue(uint _value) public {
    value = _value;
  }

  function getValue() public view returns (uint) {
    return value;
  }

  function getValueX2() public view returns (uint) {
    return value * 2;
  }
}

