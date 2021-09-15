// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

contract Forwarder {
    function checker(bytes memory execData)
        external
        view
        returns (bool, bytes memory)
    {
        return (true, execData);
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
    "enabled": false,
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