pragma solidity ^0.8.6;

error ErrorMessage(string message);

contract Test{
  uint public _value;

  constructor(uint value) public {
    _value = value;
  }

  function changeValue(uint value) public {
    if (value > 100) {
      revert ErrorMessage("Value must be > 100");
    }
    else {
      _value += value;
    }
  }
}

