/**
 *Submitted for verification at Etherscan.io on 2022-01-04
*/

// SPDX-License-Identifier: GPL-3.0


pragma solidity ^0.8.0;
  
// Build the Contract
contract educacion
{
    // Create a structure for 
    // student details
    struct Student
    {
        int ID;
        string fName;
        string lName;
        int marks;
    }
  
    address owner;
    int public stdCount = 0;
    mapping(int => Student) public stdRecords;
  
    modifier onlyOwner
    {
        require(owner == msg.sender);
        _;
    }
    constructor()
    {
        owner=msg.sender;
    }
  
    // Create a function to add 
    // the new records
    function addNewRecords(int _ID, 
                           string memory _fName,
                           string memory _lName,
                           int _marks) public onlyOwner
    {
        // Increase the count by 1
        stdCount = stdCount + 1;
  
        // Fetch the student details 
        // with the help of stdCount
        stdRecords[stdCount] = Student(_ID, _fName, 
                                       _lName, _marks);
    }
  
    // Create a function to add bonus marks 
    function bonusMarks(int _bonus) public onlyOwner
    {
         stdRecords[stdCount].marks = 
                    stdRecords[stdCount].marks + _bonus;
    }
}