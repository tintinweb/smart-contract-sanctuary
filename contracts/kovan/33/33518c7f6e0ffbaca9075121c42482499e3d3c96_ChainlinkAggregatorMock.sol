/**
 *Submitted for verification at Etherscan.io on 2021-07-15
*/

pragma solidity 0.6.10;

contract ChainlinkAggregatorMock {
  int256 public latestAnswer;
  uint256 public latestTimestamp;

  constructor(int256 _latestAnswer) public {
    setLatestAnswer(_latestAnswer);
  }

  function setLatestAnswer(int256 _latestAnswer) public {
    latestAnswer = _latestAnswer;
    latestTimestamp = now;
  }
}