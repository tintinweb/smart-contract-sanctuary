// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.6;

interface IDCASwapper {
  /// @notice A pair to swap
  struct PairToSwap {
    // The pair to swap
    address pair;
    // Path to execute the best swap possible
    bytes swapPath;
  }

}

contract PairReturner {

  function workable() external returns (IDCASwapper.PairToSwap[] memory _pairs, uint32[] memory _smallestIntervals) {

    _pairs = new IDCASwapper.PairToSwap[](2);
    _smallestIntervals = new uint32[](2);

    _pairs[0] = IDCASwapper.PairToSwap({pair: 0x41D350809AaAbE3c2C49F1972C1dDc0c12F21645, swapPath: '0x123'});
    _pairs[1] = IDCASwapper.PairToSwap({pair: 0x41D350809AaAbE3c2C49F1972C1dDc0c12F21645, swapPath: '0x123'});

    _smallestIntervals[0] = 1;
    _smallestIntervals[1] = 1;
  }

  function work(IDCASwapper.PairToSwap[] memory _pairs, uint32[] memory _smallestIntervals) external returns (bool) {
    return true;
  }
}