/**
 *Submitted for verification at Etherscan.io on 2021-06-17
*/

//SPDX-License-Identifier: Unlicense
pragma solidity =0.8.4;


contract Lottery {

  event LotteryWinner(
    address indexed winner
  );

  function getRandom()
      internal
      view
      returns (uint256)
  {
      return uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty)));
  }

  function play(uint256 candidate) external {
    if (candidate == getRandom()) {
      emit LotteryWinner(tx.origin);
    } 
  }
 
}