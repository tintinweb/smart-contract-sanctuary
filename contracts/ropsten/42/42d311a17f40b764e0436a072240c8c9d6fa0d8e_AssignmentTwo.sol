pragma solidity ^0.5.0;

contract AssignmentTwo {
    
    uint public studentNumber;
    address public student;
    uint public gasUsed;
    
    constructor() public {
        student = msg.sender;
    }
    
    function setStudentNumber(uint _studentNumber) public {
        studentNumber = _studentNumber;
    }
   
    function setgasUsed(uint _gasUsed) public {
        gasUsed = _gasUsed;
    }
}