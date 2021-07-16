//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Test {
    uint256 public number = 0;

    function updateNumber(uint256 _number) external {
        number = _number;
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 50
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
  "metadata": {
    "useLiteralContent": true
  },
  "libraries": {}
}