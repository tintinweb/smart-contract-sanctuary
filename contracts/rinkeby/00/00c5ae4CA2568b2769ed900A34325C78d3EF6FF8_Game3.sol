//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

contract Game3 {
  event Winner(address winner);

  function win() payable public {
    require(msg.value <= 1 gwei);

    if(address(this).balance >= 3 gwei) {
      emit Winner(msg.sender);
    }
  }
}