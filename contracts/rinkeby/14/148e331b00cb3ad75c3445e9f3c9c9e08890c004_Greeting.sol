/**
 *Submitted for verification at Etherscan.io on 2022-01-01
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.6.6;

contract Greeting {

 string _Greeting;

 function setGreeting() public {
   _Greeting = "Good morning";
 }

 function getGreeting() public view returns(string memory){
   return _Greeting;
 }

}