//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.6;

contract Lab1 {
  bool completed = false;

  event DoLab(address indexed from);

  function doLab() public{
    completed = true;
    emit DoLab(msg.sender);
  }
  function isCompleted() public view returns (bool){
    return completed;
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