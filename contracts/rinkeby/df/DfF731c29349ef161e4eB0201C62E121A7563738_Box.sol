//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Box {
  uint public x;

  function initialize() external {
    x = 10;
  }
}

contract BoxV2 {
  uint public x;

  function getXDoubled() external view returns(uint) {
    return x * 2;
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