/**
 *Submitted for verification at Etherscan.io on 2021-10-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract test1{
   
   address public temp1;
   uint public temp2;
   
   function test() public{
       temp1 = msg.sender;
       temp2 = 10;
   }
    
}