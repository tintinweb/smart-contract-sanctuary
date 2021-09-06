// SPDX-License-Identifier: MIT
pragma solidity ^0.6.8;

contract Migrations {
    address public owner;
    uint public last_completed_migration;

    constructor() public {
        owner = msg.sender;
    }

    modifier restricted() {
        if (msg.sender == owner) _;
    }

    function setCompleted(uint completed) public restricted {
        last_completed_migration = completed;
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 1500
  },
  "evmVersion": "constantinople",
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