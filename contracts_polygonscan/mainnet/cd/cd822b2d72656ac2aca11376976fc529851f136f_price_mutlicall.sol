/**
 *Submitted for verification at polygonscan.com on 2021-08-06
*/

// Sources flattened with hardhat v2.5.0 https://hardhat.org

// File contracts/ChainLink/AggregatorV3Interface.sol

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

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


// File contracts/LOTTI_LENDING/price_mutlicall.sol


pragma solidity ^0.8.0;

contract price_mutlicall {

    function getThePrice(address dataFeed_) public view returns (int) {
        (,int price,,,) = AggregatorV3Interface(dataFeed_).latestRoundData();
        return price;
    }

    function getThePriceMultiCall(address[] calldata dataFeeds_) public view returns (int[] memory){
        int[] memory results = new int[](dataFeeds_.length);
        for(uint256 i=0; i< dataFeeds_.length; i++){
            (,int price,,,) = AggregatorV3Interface(dataFeeds_[i]).latestRoundData();
            results[i] = price;
        }
        return results;
    } 
}