// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

contract TestStringInput {
    mapping(bytes32 => uint) public prices;

    function setCustomPrices(string[] calldata symbolsInput, uint[] calldata pricesInput) external {
        require(symbolsInput.length == pricesInput.length, "symbol and price length should match");
        for(uint i = 0; i < symbolsInput.length; i++){
            bytes32 symbolHash = keccak256(abi.encodePacked(symbolsInput[i]));
            prices[symbolHash] = pricesInput[i];
        }
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "istanbul",
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