// SPDX-License-Identifier: MIT

pragma solidity ^0.5.5;


contract TestToken {

    string public constant name = "test";
    uint256 public constant totalSupply = 1000 * 10 ** 18;

}

{
  "optimizer": {
    "enabled": true,
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