/**
 *Submitted for verification at Etherscan.io on 2021-11-17
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;


contract myContract{
  uint public peopleCount = 0;
  
  mapping(uint => Person) public people;
  
  struct Person {
      uint _id;
      string _Firstname;
      string _Lastname;
  }
   
   function addPerson(string memory _Firstname, string memory _Lastname) public{
       peopleCount +=1;
       people[peopleCount]=Person(peopleCount, _Firstname, _Lastname);
   } 
}