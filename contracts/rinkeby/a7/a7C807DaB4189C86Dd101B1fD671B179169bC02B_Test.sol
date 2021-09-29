// SPDX-License-Identifier: MIT License

pragma solidity ^0.8.6;

error ErrorMessage(string message);

contract Test{
  uint public _value;
  uint public _value2;

  constructor(uint value, uint value2) {
    _value = value;
    _value2 = value2;
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

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}