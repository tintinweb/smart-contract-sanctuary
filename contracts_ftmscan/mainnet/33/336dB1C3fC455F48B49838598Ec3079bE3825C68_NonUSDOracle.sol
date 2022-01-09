/**
 *Submitted for verification at FtmScan.com on 2022-01-09
*/

/**
 *Submitted for verification at FtmScan.com on 2022-01-09
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

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


contract NonUSDOracle {
    AggregatorV3Interface immutable public srcOracle;
    AggregatorV3Interface immutable public targetOracle;

    constructor(AggregatorV3Interface _srcOracle, AggregatorV3Interface _targetOracle) public {
        srcOracle = _srcOracle;
        targetOracle = _targetOracle;
    }

    function decimals() public view returns (uint8) {
        return targetOracle.decimals();
    }

    function latestRoundData() public view
        returns
        (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 timestamp,
            uint80 answeredInRound
        )
    {
        int targetAnswer;
        int srcAnswer;
        uint targetTimestamp;
        uint srcTimestamp;

        (roundId, targetAnswer, startedAt, targetTimestamp, answeredInRound) = targetOracle.latestRoundData();
        (, srcAnswer, , srcTimestamp,) = srcOracle.latestRoundData();

        uint srcDecimals = srcOracle.decimals();

        answer = targetAnswer * int(10 ** srcDecimals) / srcAnswer;
        timestamp = srcTimestamp > targetTimestamp ? targetTimestamp : srcTimestamp; // take the minimum

        // check if there was an overflow in calculation - if there was, return 0 timestamp and answer
        bool overflow = false;
        if(targetAnswer > type(int128).max) overflow = true;
        if(srcDecimals > 18) overflow = true;

        if(overflow) {
            timestamp = 0;
            answer = 0;
        }
    }
}