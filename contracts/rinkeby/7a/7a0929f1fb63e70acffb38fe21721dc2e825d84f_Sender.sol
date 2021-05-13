/**
 *Submitted for verification at Etherscan.io on 2021-05-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

contract Sender {

  function send(address payable _receiver) public payable {
    _receiver.transfer(address(this).balance);
  }

}