// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;


interface IPriceConsumer {
    function getLatestPrice() external view returns (int);
}

library PriceConsumer {
    function getSpotPrice(address _priceConsumer) external view returns (uint256) {
        // Feeds always return a number with 8 decimals, that represents the price of 1 asset in USD
        return uint256(IPriceConsumer(_priceConsumer).getLatestPrice());
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
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