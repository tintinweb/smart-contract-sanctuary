// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract BroadcastWithHashcash {
    event Broadcast(bytes32 value, uint256 timestamp) anonymous;

    uint256 public immutable timestampDiff;
    uint256 public immutable difficulty; // average number of trials

    constructor(uint256 timestampDiff_, uint256 difficulty_) {
        timestampDiff = timestampDiff_;
        difficulty = difficulty_;
    }

    function broadcast(
        bytes32 value,
        uint256 timestamp,
        uint256 counter
    ) external {
        require(block.timestamp - timestamp < timestampDiff);
        require(isValidHashcash(value, timestamp, counter));
        emit Broadcast(value, block.timestamp);
    }

    function isValidHashcash(
        bytes32 value,
        uint256 timestamp,
        uint256 counter
    ) public view returns (bool) {
        bytes32 hashed = keccak256(abi.encode(value, timestamp, counter));
        uint256 ceiling = type(uint256).max / difficulty;
        return uint256(hashed) < ceiling;
    }
}

{
  "evmVersion": "istanbul",
  "libraries": {},
  "metadata": {
    "bytecodeHash": "ipfs",
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "remappings": [],
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