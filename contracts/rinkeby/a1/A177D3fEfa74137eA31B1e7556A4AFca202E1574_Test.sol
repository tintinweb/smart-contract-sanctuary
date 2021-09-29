// SPDX-License-Identifier: MIT License

pragma solidity ^0.8.6;

contract Test{
  uint public _value;
  uint public _value2;

  constructor(uint value, uint value2) {
    _value = value;
    _value2 = value2;
  }

  function changeValue(uint value) public {
    require(value > 100, "Value must be <= 100");
    _value += value;
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