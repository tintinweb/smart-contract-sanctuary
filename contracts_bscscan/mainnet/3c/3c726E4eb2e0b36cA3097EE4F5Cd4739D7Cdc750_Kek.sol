// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

contract Kek {
    function kek(string memory txretard) external pure returns(bytes32) {
        return keccak256(bytes(txretard));
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
    "runs": 10000
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