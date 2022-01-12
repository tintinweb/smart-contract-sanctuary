pragma solidity ^0.8.0;

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

contract AggregatorV3MATIC{
    uint80 public _roundId = 18446744073709560000;

    address public oracle = 0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada;

    function latestRoundData()
    external
    view
    returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    ){
      return AggregatorV3Interface(oracle).getRoundData(_roundId);
    }

    function addRoundId() external{
        _roundId += 1;
    }

    function setRoundId(uint80 rid) external{
        _roundId = rid;
    }

}