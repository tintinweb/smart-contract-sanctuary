pragma solidity 0.8.4;

// SPDX-License-Identifier: UNLICENSED

contract ExampleExternalContract {

  bool public completed;

  function complete() public payable {
    completed = true;
  }

}