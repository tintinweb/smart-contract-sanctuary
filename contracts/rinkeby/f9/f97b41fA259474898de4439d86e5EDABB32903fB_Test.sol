// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.6;

contract Test {
    address public owner;
    uint256 count = 12;

    constructor() {
        owner = msg.sender;
    }

    modifier ifAdmin() {
        require(owner == msg.sender);
        _;
    }

    function inc() external {
        count++;
    }

    function reset() external ifAdmin {
        count = 0;
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "berlin",
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