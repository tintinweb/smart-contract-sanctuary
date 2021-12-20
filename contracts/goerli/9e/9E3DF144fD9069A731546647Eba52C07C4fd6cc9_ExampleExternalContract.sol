/**
 *Submitted for verification at Etherscan.io on 2021-12-19
*/

pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

contract ExampleExternalContract {

  bool public completed;

  function complete() public payable {
    completed = true;
  }

}