// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract EventEmitter {
  constructor() {
  }

  event Event();

  function create(uint256 number) public {
    while (number != 0) {
      emit Event();
      number--;
    }
  }
}

