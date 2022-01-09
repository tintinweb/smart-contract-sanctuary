/**
 *Submitted for verification at Etherscan.io on 2022-01-09
*/

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

contract MockAggregator {
  uint256 private _latestAnswer;
  string public symbol;
  address public addr;
  uint256 public decimals;

  event AnswerUpdated(uint256 indexed current, uint256 indexed roundId, uint256 timestamp);

  constructor(uint256 _initialAnswer, string memory _symbol, address _addr, uint256 _decimals) public {
    _latestAnswer = _initialAnswer;
    symbol = _symbol;
    addr = _addr;
    decimals = _decimals;
    emit AnswerUpdated(_initialAnswer, 0, now);
  }

  function latestAnswer() external view returns (uint256) {
    return _latestAnswer;
  }

  function setPrice(uint256 _newPrice) public {
    _latestAnswer = _newPrice; 
    emit AnswerUpdated(_newPrice, 0, now);
  }
}