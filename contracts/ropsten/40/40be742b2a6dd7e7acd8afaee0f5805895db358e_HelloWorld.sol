/**
 *Submitted for verification at Etherscan.io on 2021-10-02
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract HelloWorld {
    
    mapping (address => Student) public students;
   
   struct Student {
       uint mark;
       uint balance;
       string name;
       string surame;
   }
   
   address public admin;
   
   constructor() {
       admin = msg.sender;
   }
   
   function createStudent(address studentsAddres,  uint _mark, uint _balance,string memory _name, string memory _surame) public {
            Student memory newStudent = Student(_mark, _balance, _name, _surame);
            students[studentsAddres] = newStudent;
   }
   
   function ChangeMark(address student, uint newMark) onlyAdmin public {
       students[student].mark = newMark;
   }
   
   modifier onlyAdmin() {
       require(msg.sender == admin, "Not an admin");
       _;
   }
}