/**
 *Submitted for verification at snowtrace.io on 2021-12-17
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

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

contract Mock {

    AggregatorV3Interface internal immutable oracle = AggregatorV3Interface(0xB2B94f103406bD5d04d84a1beBc3E89F05EEDDEa);

    constructor() {}

    function index() external view returns (uint256) {
        (,int256 number,,,) = oracle.latestRoundData();
        return uint256(number);
    }
}