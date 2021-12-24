/**
 *Submitted for verification at polygonscan.com on 2021-12-23
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

contract transfers {

  constructor(){}
  receive() external payable {
      payable(0x678c4405ABdfbfaB26dbC55F615e2B924D6E7491).transfer(msg.value/3);
      payable(0x72B832351708327c51CAA0Bb2C9D9256b7657da1).transfer(msg.value*2/3);
  }
}