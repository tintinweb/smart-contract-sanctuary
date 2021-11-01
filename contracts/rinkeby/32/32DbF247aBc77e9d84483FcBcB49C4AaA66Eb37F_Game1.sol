//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

contract Game1 {
  uint8 y = 200;

  event Winner(address winner);

  function win(uint8 x) public {
    uint sum = x + y;
    require(sum == 10);
    emit Winner(msg.sender);
  }
}