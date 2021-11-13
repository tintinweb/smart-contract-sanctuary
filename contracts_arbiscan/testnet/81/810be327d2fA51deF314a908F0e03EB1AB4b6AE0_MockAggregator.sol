// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.7;

contract MockAggregator {
  int256 private _latestAnswer;

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 timestamp);

  constructor(int256 _initialAnswer) {
    _latestAnswer = _initialAnswer;
    emit AnswerUpdated(_initialAnswer, 0, block.timestamp);
  }

  function latestAnswer() external view returns (int256) {
    return _latestAnswer;
  }

  function getTokenType() external pure returns (uint256) {
    return 1;
  }
}