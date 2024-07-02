pragma solidity 0.5.17;

contract MockAggregator {
    int256 public latestAnswer;
    uint public decimals = 8;

    function setLatestAnswer(int256 _latestAnswer) public {
        latestAnswer = _latestAnswer;
    }

    function latestRoundData() external view returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    ) {
        return (1, latestAnswer, 1, 1, 1);
    }
}