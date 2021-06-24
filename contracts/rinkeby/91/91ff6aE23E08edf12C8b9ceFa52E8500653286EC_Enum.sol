// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract Enum {
  enum State {
    OFF,
    ON
  }

  State public currentState = State.OFF;

  function updateState(State _newState) external payable {
    currentState = _newState;
  }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}