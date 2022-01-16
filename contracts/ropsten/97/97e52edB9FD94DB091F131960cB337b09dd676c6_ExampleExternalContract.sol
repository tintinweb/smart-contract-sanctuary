pragma solidity 0.8.4;
// SPDX-License-Identifier: MIT

contract ExampleExternalContract {

  bool public completed;

  function complete() public payable {
    completed = true;
  }

}