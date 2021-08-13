// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Rarify
 */
contract Rarify {
    function isRarify() external pure returns (bool) {
        return true;
    }

    function rarity(uint8 randNumber) external pure returns (uint8) {

        randNumber++;

        return randNumber;
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 20
  },
  "evmVersion": "london",
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