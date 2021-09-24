//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;

/**
 * @title EthPriceFeed
 * @author Protofire
 * @dev This contract returns always 10^18 as ETH/ETH price.
 * It is ment to be used on EurPriceFeed contract as the `assetEthFeed` for the xETH token.
 *
 */
contract EthPriceFeed {
    uint256 public decimals = 18;
    int256 public constant ONE = 10**18;

    function latestAnswer() external pure returns (int256) {
        return ONE;
    }
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