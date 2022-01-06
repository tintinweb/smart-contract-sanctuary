/**
 *Submitted for verification at FtmScan.com on 2022-01-06
*/

// Sources flattened with hardhat v2.8.0 https://hardhat.org

// File contracts/Dependencies/AggregatorV3Interface.sol

// SPDX-License-Identifier: MIT
// Code from https://github.com/smartcontractkit/chainlink/blob/master/evm-contracts/src/v0.6/interfaces/AggregatorV3Interface.sol

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


// File contracts/B.Protocol/StableOracle.sol


pragma solidity 0.6.11;

contract StableOralce {
    AggregatorV3Interface immutable oracle;

    constructor(AggregatorV3Interface _oracle) public {
        oracle = _oracle;
    }

    function decimals() public view returns (uint8) {
        return oracle.decimals();
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
        (roundId, answer, startedAt, timestamp, answeredInRound) = oracle.latestRoundData();
        timestamp = now; // override timestamp
    }

    function tal(int x) public returns(uint) {
        return uint(-x);
    }
}