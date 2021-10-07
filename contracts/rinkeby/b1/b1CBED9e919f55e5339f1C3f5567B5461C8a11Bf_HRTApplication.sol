// SPDX-License-Identifier: MIT

pragma solidity =0.8.4;

contract HRTApplication {
    event Application(bytes data, address sender, address origin);

    bytes public publicKey;

    constructor(bytes memory _publicKey) {
        publicKey = _publicKey;
    }

    function sendApplication(bytes calldata data) public {
        require(msg.sender != tx.origin, "Must apply from a smart contract!");
        emit Application(data, msg.sender, tx.origin);
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
        "devdoc",
        "userdoc",
        "metadata",
        "abi"
      ]
    }
  }
}