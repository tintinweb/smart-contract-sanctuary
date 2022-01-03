/**
 *Submitted for verification at BscScan.com on 2022-01-03
*/

// SPDX-License-Identifier: Unlicensed 

pragma solidity 0.8.10;


interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData()
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



contract PriceConsumer {

    AggregatorV3Interface internal priceFeed;

    constructor()  {
        priceFeed = AggregatorV3Interface(0xe3cb4136E9e8f503e7C5244960Ca19746cC9A9e8);
    }
  
    /**
     * Returns the latest price
     */
    function latestRoundData() public view returns (uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound) {
        return priceFeed.latestRoundData();
    }

    /**
     * Returns the timestamp of the latest price update
     */
    function getRoundData() public view returns (uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound) {
        return priceFeed.getRoundData();
    }
}