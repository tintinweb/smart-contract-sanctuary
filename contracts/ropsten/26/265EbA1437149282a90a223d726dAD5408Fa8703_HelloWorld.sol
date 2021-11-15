/**
 *Submitted for verification at Etherscan.io on 2021-11-15
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.6.0;

contract HelloWorld{
   uint a = 3;
   uint b = 2;
   
   function add(uint x,uint y) pure public returns(uint){
       return x+y;
   }
}