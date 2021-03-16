//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.0;

contract Counter {
  event Counted(uint);
  uint theCount;

  function count() external {
    theCount++;
    emit Counted(theCount);
  }
}