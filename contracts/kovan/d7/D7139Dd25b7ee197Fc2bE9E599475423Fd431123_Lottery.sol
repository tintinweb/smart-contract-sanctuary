// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.3;

contract Lottery {
  address public manager;

  constructor() {
    manager = msg.sender;
  }
}

