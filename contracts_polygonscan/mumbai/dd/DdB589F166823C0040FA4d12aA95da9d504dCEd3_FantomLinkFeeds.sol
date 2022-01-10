// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract FantomLinkFeeds {

    AggregatorV3Interface internal priceFeed;

    /**
    * Network: Fantom Testnet
    * Aggregator: FTM/USD
    * Address: 0xe04676B9A9A2973BCb0D1478b5E1E9098BBB7f3D
    * URL: https://docs.chain.link/docs/fantom-price-feeds/
    */
    constructor() {
        priceFeed = AggregatorV3Interface(0x0715A7794a1dc8e42615F059dD6e406A6594651A);
    }

    /**
    * Returns the latest price
    */
    function getLatestPrice() public view returns (int) {
    (
        , 
        int price,
        ,
        ,
    ) = priceFeed.latestRoundData();
        return price;
    }
}

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