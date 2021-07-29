// SPDX-License-Identifier: UNLICENSED
// the purpose of this contract is to provide an address that certainly has no private key associated with it
// it has no functions so it cannot transfer tokens that have been sent to it
pragma solidity 0.7.3;

contract BurnAddress {

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