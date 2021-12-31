/**
 *Submitted for verification at Etherscan.io on 2021-12-31
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

contract Game2 {
  uint8 y = 210;

  event Winner(address winner);

  function win(uint8 x) public {
    uint8 sum = x + y;
    require(sum == 10);
    emit Winner(msg.sender);
  }
}