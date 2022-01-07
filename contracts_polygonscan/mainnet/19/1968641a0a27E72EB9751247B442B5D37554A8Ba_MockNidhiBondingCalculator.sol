// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

contract MockNidhiBondingCalculator {
  function valuation(address _pair, uint256 amount_)
    external
    view
    returns (uint256 _value)
  {
    return 0;
  }
}