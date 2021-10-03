/**
 *Submitted for verification at BscScan.com on 2021-10-02
*/

//SPDX-License-Identifier: MIT


pragma solidity ^0.8.9;















contract Test1 {
  function test1() public pure returns (bool){
    return true;
  }
}


















contract Test2 {
  function test2() public pure returns (bool){
    return true;
  }
}








contract Test0 is Test1, Test2{
  function test0() public pure returns (bool){
    return true;
  }
}