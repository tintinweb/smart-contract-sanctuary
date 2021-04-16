// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

contract MockOracle {
    mapping(string=>uint) public priceOf;
    function setPrice(string memory symbol, uint price) public {
        priceOf[symbol] = price;
    }

    function getPrice(string memory symbol) public view returns(uint) {
        uint n = uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty)))%20;
        uint dire = uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty)))%2;
        uint p = 0;
        if (dire == 0) {
            p = priceOf[symbol]*(1e18+n*1e16)/1e18;
        } else {
            p = priceOf[symbol]*(1e18-n*1e16)/1e18;
        }
        return p;
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