//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Gm {

    event EthereumSaysGMBack();

    function gm() external {
        emit EthereumSaysGMBack();
    }

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
  "metadata": {
    "useLiteralContent": true
  },
  "libraries": {}
}