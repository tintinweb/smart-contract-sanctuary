pragma solidity ^0.4.22;

contract AssignmentTwo 
{
    
    uint public studentNumber;
    uint public GasUsed;
    address public student;
    
    constructor() public {
        student = msg.sender;
    }
    
    function setStudentNumber(uint _studentNumber) public {
        studentNumber = _studentNumber;
    }
    function setGasUsed(uint _gasUsed) public {
        GasUsed = _gasUsed;
    }
       
}