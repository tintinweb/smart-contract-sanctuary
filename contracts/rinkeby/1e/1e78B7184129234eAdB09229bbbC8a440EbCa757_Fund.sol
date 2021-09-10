/**
 *Submitted for verification at Etherscan.io on 2021-09-09
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

//import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
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

contract Fund {
    //0x8A753747A1Fa494EC906cE90E9f37563A8AF630e

    function fund() public payable {

    }

    function getPrice(address pair) public view returns(uint256){

        AggregatorV3Interface priceFeed = AggregatorV3Interface(pair);

    (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound

      ) = priceFeed.latestRoundData();
      return uint256(answer);
    } 

}