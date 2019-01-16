pragma solidity ^0.4.24;

contract assignmentTwo {
    
    uint public studentNumber;
    address public student;
    
    // sub-requirement 1
    uint public gasUsed;

    constructor() public {
        student = msg.sender;
    }

    function setStudentNumber(uint _studentNumber) public {
        studentNumber = _studentNumber;
    }
    
    // sub-requirement 2
    function setGasUsed( uint _gasUsed) public{
        gasUsed = _gasUsed;
    }
}