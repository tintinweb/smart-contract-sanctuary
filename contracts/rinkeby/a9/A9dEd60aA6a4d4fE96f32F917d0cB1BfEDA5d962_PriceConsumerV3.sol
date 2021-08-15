// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AggregatorV3Interface.sol";

contract PriceConsumerV3 {

    AggregatorV3Interface internal priceFeedEth;
    AggregatorV3Interface internal priceFeedMatic;

    /**
     * Network: Mumbai
     * Aggregator: ETH/USD
     * Decimals: 8
     * Address: 0x0715A7794a1dc8e42615F059dD6e406A6594651A
     */

    /* 
     * @notice change address when deploying to mainnet
     */

    constructor() {
        priceFeedEth = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        priceFeedMatic = AggregatorV3Interface(0xd8bD0a1cB028a31AA859A21A3758685a95dE4623);

    }

    /**
     * Returns the latest price
     */

    function ethPrice() public view returns (int) {
        (, int price , , , ) = priceFeedEth.latestRoundData();
        return price ; // 8 decimals
    }

    function maticPrice() public view returns (int) {
        (, int price , , , ) = priceFeedMatic.latestRoundData();
        return price ; // 8 decimals
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