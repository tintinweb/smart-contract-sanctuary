// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract KuponNft {
  uint256 private counter = 0;

  constructor() {
    increase();
  }

  // views
  function getCounter() public view returns(uint256) {
    return counter;
  }

  function increase() public {
    counter += 1;
  }
}