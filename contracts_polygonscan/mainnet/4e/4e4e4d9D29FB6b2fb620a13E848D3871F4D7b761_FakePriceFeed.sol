// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

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

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "@chainlink/contracts/src/v0.7/interfaces/AggregatorV3Interface.sol";

contract FakePriceFeed is AggregatorV3Interface {
    uint8 decimals_;
    string description_;
    uint256 version_;

    struct Round {
        uint80 roundId;
        int256 answer;
        uint256 startedAt;
        uint256 updatedAt;
        uint80 answeredInRound;
    }
    mapping(uint80 => Round) rounds;
    uint80 latestRoundId;

    constructor(
        uint8 _decimals,
        string memory _description,
        uint256 _version
    ) {
        decimals_ = _decimals;
        description_ = _description;
        version_ = _version;
    }

    function decimals() external view override returns (uint8) {
        return decimals_;
    }

    function description() external view override returns (string memory) {
        return description_;
    }

    function version() external view override returns (uint256) {
        return version_;
    }

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function getRoundData(uint80 roundId_)
        public
        view
        override
        returns (
            uint80 _roundId,
            int256 _answer,
            uint256 _startedAt,
            uint256 _updatedAt,
            uint80 _answeredInRound
        )
    {
        Round memory _round = rounds[roundId_];
        _roundId = _round.roundId;
        _answer = _round.answer;
        _startedAt = _round.startedAt;
        _updatedAt = _round.updatedAt;
        _answeredInRound = _round.answeredInRound;
    }

    function latestRoundData()
        public
        view
        override
        returns (
            uint80 _roundId,
            int256 _answer,
            uint256 _startedAt,
            uint256 _updatedAt,
            uint80 _answeredInRound
        )
    {
        return getRoundData(latestRoundId);
    }

    function addRound(
        uint80 _roundId,
        int256 _answer,
        uint256 _startedAt,
        uint256 _updatedAt,
        uint80 _answeredInRound
    ) external {
        rounds[_roundId] = Round(_roundId, _answer, _startedAt, _updatedAt, _answeredInRound);
        latestRoundId = _roundId;
    }
}