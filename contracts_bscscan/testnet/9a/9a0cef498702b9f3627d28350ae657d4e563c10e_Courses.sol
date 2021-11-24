/**
 *Submitted for verification at BscScan.com on 2021-11-24
*/

pragma solidity ^0.4.18;

contract Owned {
    address owner;
    
    function Owned() public {
        owner = msg.sender;
    }
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
}

contract Courses is Owned {
    
    struct Instructor{
        uint age;
        bytes16 fName;
        bytes16 lName;
    }
    
    mapping (address => Instructor ) instructors;
    address[] public instructorAccts;
    
    event instructorInfo(
        uint age,
        bytes16 fName,
        bytes16 lName
    );
    
    
    
    function setInstructor(address _address, uint _age, bytes16 _fName, bytes16 _lName) onlyOwner public {
        var instructor = instructors[_address];
        
        instructor.age = _age;
        instructor.fName = _fName;
        instructor.lName = _lName;
        // ?
        instructorAccts.push(_address) -1;
        instructorInfo(_age, _fName, _lName );
        
        
    }
    
    function getInstructors() view public returns(address[]){
        return instructorAccts;
    }
    
    function getInstructor(address _address) view public returns(uint, bytes16, bytes16){
        return (instructors[_address].age, instructors[_address].fName, instructors[_address].lName );
    }
    
    function countInstructor() view public returns(uint){
        return instructorAccts.length;
    }
    
    
    
}