/**
 *Submitted for verification at Etherscan.io on 2021-11-17
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;


contract myContract{
  Person[] public people;
  
  uint public peopleCount;
  
  struct Person {
      string _Firstname;
      string _Lastname;
  }
   
   function addPerson(string memory _Firstname, string memory _Lastname) public{
       people.push(Person(_Firstname, _Lastname));
       peopleCount +=1;
   } 
}