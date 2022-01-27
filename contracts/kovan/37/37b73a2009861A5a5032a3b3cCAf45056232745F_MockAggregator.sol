/**
 *Submitted for verification at Etherscan.io on 2022-01-26
*/

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

contract MockAggregator {
  uint256 private _latestAnswer;
  string public symbol;
  address public addr;
  uint256 public decimals;

  event AnswerUpdated(uint256 indexed current, uint256 indexed roundId, uint256 timestamp);

  constructor(string memory _symbol, uint256 _decimals) public {
    _latestAnswer = 10000000000000;
    symbol = _symbol;
    decimals = _decimals;
  }

  function latestAnswer() external view returns (uint256) {
    return _latestAnswer;
  }

  function setPrice(uint256 _newPrice) public {
    _latestAnswer = _newPrice; 
    emit AnswerUpdated(_newPrice, 0, now);
  }
}