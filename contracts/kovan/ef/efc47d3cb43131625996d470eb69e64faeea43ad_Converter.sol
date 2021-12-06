/**
 *Submitted for verification at Etherscan.io on 2021-12-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

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

contract Converter {

    AggregatorV3Interface internal priceFeed;

    /**
     * Network: Kovan
     * Aggregator: LINK/USD
     * Address: 0x396c5E36DD0a0F5a5D33dae44368D4193f69a1F0
     */
    constructor() {
        priceFeed = AggregatorV3Interface(0x396c5E36DD0a0F5a5D33dae44368D4193f69a1F0);
    }

    function getLatestPrice() public view returns (uint256) {
        (,int price,,,) = priceFeed.latestRoundData();
        return uint256(price);
    }
    // (converts the user LINK amount to USD) + 18 zeroes!!
    function getConversionRate(uint256 LinkAmt) public view returns(uint256){
        uint256 LinkPrice = getLatestPrice();
        uint256 LinkAmtInUsd =  (LinkAmt * LinkPrice) / 100000000;
        return LinkAmtInUsd;
    }
}