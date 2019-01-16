pragma solidity ^0.4.22;

contract assignmentTwo {
    
    uint public studentNumber;
    uint public GasUsed;
    address public student;
    
    constructor() public {
        student = msg.sender;
        GasUsed = 0;
    }
    
    function setStudentNumber(uint _studentNumber) public {
        studentNumber = _studentNumber;
    }
    function setGasUsed(uint _gasUsed) public {
        GasUsed = _gasUsed;
    }  
}