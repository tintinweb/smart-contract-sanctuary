/**
 *Submitted for verification at polygonscan.com on 2021-09-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract Bunny {
  address[] a;

  function sendmoney(address payable affilate) public payable {
    
    affilate.transfer(msg.value/2);
    
  }
}