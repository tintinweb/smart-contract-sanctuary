/**
 *Submitted for verification at Etherscan.io on 2022-01-06
*/

// SPDX-License-Identifier: GPL-3.0

 pragma solidity ^0.8.0;

 contract Token {
     string myname = "abc";

     function getName () public view returns (string memory)  {
         return myname;
     }

     function setName (string memory newName) public {
         myname = newName;
     }
 }