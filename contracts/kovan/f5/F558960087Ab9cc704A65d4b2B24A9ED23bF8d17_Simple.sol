/**
 *Submitted for verification at Etherscan.io on 2021-12-29
*/

//SPDX-License-Identifier:MIT

pragma solidity ^0.8.9;

contract Simple{

  string public forFoo = "Hello World";
  string public forFun = "Function";
  
  function foo()public pure returns(string memory){
    return "Hello World";
  }

  function fun()public pure returns(string memory){
    return "Function";
  }
}