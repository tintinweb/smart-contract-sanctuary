/**
 *Submitted for verification at Etherscan.io on 2021-06-14
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
  

contract StructDemo{
  
   // Structure of employee
   struct Person{
       
       // State variables
      
       bytes32 name;
       bytes32 passportNumber;
       int256 date;
       bool isExist;
   }
   
  
  
//mapping which is parsed through wallet address of each user
  mapping(address => Person) public person;



function addUser(bytes32 Name, bytes32 PassportNumber, int256 Date) public {

        if(person[msg.sender].isExist)
        {
            revert('user already exsists');
        }
        else
        {
            person[msg.sender].name = Name;
            person[msg.sender].passportNumber = PassportNumber;
            person[msg.sender].date = Date;
            person[msg.sender].isExist = true;
        }
        
        
        
}




}