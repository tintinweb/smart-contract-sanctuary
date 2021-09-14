/**
 *Submitted for verification at Etherscan.io on 2021-09-14
*/

/**
 *Submitted for verification at Etherscan.io on 2021-06-15
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;
  

contract VaccineContract{
  
   // Structure of employee
   struct Person{
       
       // State variables
      
       bytes32 name;
       bytes32 passportNumber;
       int256 date;
        bytes32 qrScan;
       bool isExist;
   }
   
  
  
//mapping which is parsed through wallet address of each user
  mapping(address => Person) public person;

  mapping(bytes32 => Person) public pass_person;



function addUser(bytes32 Name, bytes32 PassportNumber, int256 Date,  bytes32 QrScan) public {

        if(person[msg.sender].isExist || pass_person[PassportNumber].isExist)
        {
            revert('user already exsists');
        }
        else
        {
            person[msg.sender].name = Name;
            person[msg.sender].passportNumber = PassportNumber;
            person[msg.sender].date = Date;
             person[msg.sender].qrScan = QrScan;
            
            person[msg.sender].isExist = true;
            
            
            pass_person[PassportNumber].name = Name;
            pass_person[PassportNumber].passportNumber = PassportNumber;
            pass_person[PassportNumber].date = Date;
             person[msg.sender].qrScan = QrScan;
            pass_person[PassportNumber].isExist = true;
          
        }
        
        
        
}





}