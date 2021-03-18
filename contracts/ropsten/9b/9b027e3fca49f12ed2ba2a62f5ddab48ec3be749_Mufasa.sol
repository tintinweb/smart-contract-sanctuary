/**
 *Submitted for verification at Etherscan.io on 2021-03-18
*/

pragma solidity ^0.4.18;

contract Mufasa {
    
    struct Instructor {
        uint no;
        string keyStr;
    }
    
    mapping (address => Instructor) instructors;
    address[] public instructorAccts;
    
    function setInstructor(address _address, string _keyStr) public {
        var instructor = instructors[_address];
        
        instructor.no = 98;
        instructor.keyStr = _keyStr;

        instructorAccts.push(_address) -1;
    }
    
    function getInstructors() view public returns(address[]) {
        return instructorAccts;
    }
    
    function getInstructor(address _address) view public returns (string) {
        return (instructors[_address].keyStr);
    }
    
    function countInstructors() view public returns (uint) {
        return instructorAccts.length;
    }
}