/**
 *Submitted for verification at Etherscan.io on 2021-03-19
*/

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.7.4;

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

contract DummyChainLinkAggregatorETH is AggregatorV3Interface {

    AggregatorV3Interface public feedTokenETH;
    AggregatorV3Interface public feedETHUSD;


    constructor(address feedA, address feedB) {
        feedTokenETH = AggregatorV3Interface(feedA);
        feedETHUSD = AggregatorV3Interface(feedB);
    }

    function decimals() external view override returns (uint8) {
        // sum because we multiply the feeds, adding the exponents
        return feedETHUSD.decimals() + feedTokenETH.decimals();
    }

    function description() external view override returns (string memory) {
        return "UMA/USD";
    }

    function version() external view override returns (uint256) {
        return 1;
    }

    function getRoundData(uint80 _roundId)
        public
        view
        override
        returns (
          uint80 roundId,
          int256 answer,
          uint256 startedAt,
          uint256 updatedAt,
          uint80 answeredInRound
        ){
        return (0, 0, 0, 0, 0);
    }

    function latestRoundData()
        public
        view
        override
        returns (
          uint80 roundId,
          int256 answer,
          uint256 startedAt,
          uint256 updatedAt,
          uint80 answeredInRound
        ){
        (, int priceTokenETH, , ,) = feedTokenETH.latestRoundData();
        (, int priceETHUSD, , ,) = feedETHUSD.latestRoundData();
        return (0, priceTokenETH * priceETHUSD, 0, 0, 0);
    }


}