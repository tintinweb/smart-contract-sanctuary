pragma solidity ^0.4.22;

contract assignmentTwo {
    
    uint public studentNumber;
    address public student;
    uint public GasUsed;
    
    constructor() public {
        student = msg.sender;
    }
    function setGasused(uint fromethscan) public {
        GasUsed = fromethscan;
    }
    
    function setStudentNumber(uint _studentNumber) public {
        studentNumber = _studentNumber;
    }
       
}