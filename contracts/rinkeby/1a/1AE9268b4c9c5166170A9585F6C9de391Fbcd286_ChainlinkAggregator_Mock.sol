// SPDX-License-Identifier: bsl-1.1

/*
  Copyright 2020 Unit Protocol: Artem Zakharov ([email protected]).
*/
pragma solidity 0.7.6;

contract ChainlinkAggregator_Mock {
    int public latestAnswer;
    uint public latestTimestamp = block.timestamp;
    uint public decimals;

    address admin = msg.sender;

    event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 timestamp);

    constructor (int price, uint _decimals) public {
        latestAnswer = price;
        decimals = _decimals;
    }

    function setPrice(int price) external {
        require(msg.sender == admin, "Unit Protocol: UNAUTHORIZED");
        latestAnswer = price;
        latestTimestamp = block.timestamp;
        emit AnswerUpdated(int(price), block.timestamp, block.timestamp);
    }

    function latestRoundData()
    external
    view
    returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    ) {
        answer = latestAnswer;
        updatedAt = latestTimestamp;
    }
}

