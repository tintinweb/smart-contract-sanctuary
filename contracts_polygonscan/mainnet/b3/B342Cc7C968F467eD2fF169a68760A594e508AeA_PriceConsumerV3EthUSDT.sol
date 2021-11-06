/**
 *Submitted for verification at polygonscan.com on 2021-11-06
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;


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


contract PriceConsumerV3EthUSDT {
    AggregatorV3Interface internal priceFeed;

    /**
     * Network: Mainnet
     * Aggregator: USDT/ETH
     * Address: 0xEe9F2375b4bdF6387aa8265dD4FB8F16512A1d46
     */
    constructor() {
        priceFeed = AggregatorV3Interface(0xf9d5AAC6E5572AEFa6bd64108ff86a222F69B64d);
    }

    /**
     * Returns the latest price
     */
    function getLatestPrice() public view returns (int) {
        (
            uint80 roundID, 
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        return price;
    }
}