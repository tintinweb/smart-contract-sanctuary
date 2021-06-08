/**
 *Submitted for verification at Etherscan.io on 2021-06-08
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


contract ThisIsHellow{
   uint8  counter;
   string thingToSay;
   
   event SaidHi( string indexed msg, uint8 repeated);

   constructor(string memory newThinsToSay){
       thingToSay = newThinsToSay;
       counter = 0;
       prompt();
   }
   
   function prompt() public{
       emit SaidHi(thingToSay, counter++);
   }
   

}