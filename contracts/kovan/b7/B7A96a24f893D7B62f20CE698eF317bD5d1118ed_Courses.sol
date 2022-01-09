/**
 *Submitted for verification at Etherscan.io on 2022-01-09
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Owned{
    address owner;

    constructor(){
        owner = msg.sender;
    }

    modifier onlyOwner{
        require(msg.sender == owner);
        _;
    }
}

contract Courses is Owned{

    struct Instructor{
        uint age;
        string  fName;
        string  lName;
    }

    mapping (address => Instructor) instructors;
    address[] public instructorAccounts;

    event InstructorInfo(string _fName,string _lName,uint _age );

    function setInstructor(address _address, uint _age, string memory _fName,string memory _lName) onlyOwner public {
        Instructor storage instructor = instructors[_address];
        instructor.age = _age;
        instructor.fName = _fName;
        instructor.lName = _lName;

        instructorAccounts.push(_address);
        emit InstructorInfo(_fName, _lName, _age);
    }

    function getInstructors() public view returns(address[] memory){
        return instructorAccounts;
    }
    
    function getInstructor(address _address) public view returns(uint, string memory, string memory){
        return(instructors[_address].age,instructors[_address].fName,instructors[_address].lName);
    }
    
}