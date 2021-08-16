pragma solidity ^0.8.0;

contract Deer {
  string public name = "My Dear Deer";
  string public symbol = "DEER";
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