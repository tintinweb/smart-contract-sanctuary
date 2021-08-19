//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Greeter {
  uint public nonce = 111232131;
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