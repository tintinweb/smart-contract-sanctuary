/**
 *Submitted for verification at polygonscan.com on 2021-07-21
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library DividendPeriod {
  function firstSecond(uint256 _period, uint256 _offset, uint256 _duration) public pure returns (uint256) {
    return (_period * _duration) + _offset;
  }

  function lastSecond(uint256 _period, uint256 _offset, uint256 _duration) public pure returns (uint256) {
    return firstSecond(_period + 1, _offset, _duration);
  }

  function fromSeconds(uint256 _seconds, uint256 _offset, uint256 _duration) public pure returns (uint256) {
    
    _seconds = _seconds - _offset;
    return _seconds > _duration ? _seconds / _duration
      : 0;
  }

  function currentPeriod(uint256 _offset, uint256 _duration) public view returns (uint256) {
    return fromSeconds(block.timestamp, _offset, _duration);
  }
}