//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.7.5;

contract NowContract {
    uint32 public nowValue = 0;

    constructor () {
        computeNow();
    }

    function computeNow() public {
        nowValue = uint32(block.timestamp);
    }
}

{
  "optimizer": {
    "enabled": true,
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
  "metadata": {
    "useLiteralContent": true
  },
  "libraries": {}
}