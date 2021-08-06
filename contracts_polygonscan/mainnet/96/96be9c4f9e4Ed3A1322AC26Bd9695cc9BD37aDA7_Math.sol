// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library Math {
  function min(uint256 _a, uint256 _b) public pure returns (uint256) {
    return _a <= _b ? _a
      : _b;
  }

  function max(uint256 _a, uint256 _b) public pure returns (uint256) {
    return _a >= _b ? _a
      : _b;
  }

  function clamp(uint256 _a, uint256 _min, uint256 _max) public pure returns (uint256) {

    // _a is in range
    return _a >= _min && _a <= _max ? _a
      // _a is too small
      : _a < _min ? _min
        // _a is too large
        : _a;
  }

  uint256 public constant PERCENT_DIVISOR = 10000;
  function applyPercentage(uint256 _principal, uint256 _percent) public pure returns (uint256) {
    return (_principal * _percent) / PERCENT_DIVISOR;
  }
}