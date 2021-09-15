/**
 *Submitted for verification at Etherscan.io on 2021-09-15
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.4.16 <0.9.0;

contract helloworld{

  string Hellotext = "hello world";

  function Sayhello() public view returns (string memory){
    return Hellotext;
  }
}