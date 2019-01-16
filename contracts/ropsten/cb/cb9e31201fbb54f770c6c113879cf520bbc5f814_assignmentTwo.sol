pragma solidity ^0.4.22;

contract assignmentTwo {
    
    uint public studentNumber;
    uint public GasUsed;
    address public student;
    
    constructor() public {
        student = msg.sender;
    }
    
    function setStudentNumber(uint _studentNumber) public {
        studentNumber = _studentNumber;
    }
    
    function setGasused(uint _gasused) public {
        GasUsed = _gasused;
    }
       
}