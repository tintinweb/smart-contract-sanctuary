//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.3;

contract Game2 {
  event Winner(address winner);

  function win() payable external {
    require(msg.value <= 1 gwei);

    if(address(this).balance >= 3 gwei) {
      emit Winner(msg.sender);
    }
  }
}

