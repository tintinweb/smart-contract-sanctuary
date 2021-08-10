//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.3;

contract Game {
  event Winner(address winner);

  function win() external {
    emit Winner(msg.sender);
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