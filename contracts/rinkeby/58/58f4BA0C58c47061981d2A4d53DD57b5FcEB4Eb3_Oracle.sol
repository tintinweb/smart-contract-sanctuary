// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;


contract Oracle  {
    uint256 price;

    constructor(
        uint256 _price
    )public{
        price = _price;
    }
    function updatePrice(uint256 _price)
        public

        returns(uint256)
      {
        price = _price;
        return price;
      }

    function getPrice()
        public
        view
        returns(uint256)
      {
        return price;
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