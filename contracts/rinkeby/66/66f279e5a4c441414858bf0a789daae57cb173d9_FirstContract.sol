/**
 *Submitted for verification at Etherscan.io on 2021-04-19
*/

// SPDX-License-Identifier: AFL-3.0

pragma solidity >=0.7.0; //^0.7.5

contract FirstContract {
   string public testString = "Hello, blockchain! Vika";
   
   function cnahgeString() public {
       testString = "Hello ALL!";
   }
}