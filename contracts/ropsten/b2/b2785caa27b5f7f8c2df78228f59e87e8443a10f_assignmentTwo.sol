pragma solidity ^0.4.22;

contract assignmentTwo {
    
    uint public studentNumber;
    uint public GasUsed;
    address public student;
    
    constructor() public {
        student = msg.sender; //sender of the address
    }
    
    function setStudentNumber(uint _studentNumber) public {
        studentNumber = _studentNumber;
    }
    
     function setGasUsage(uint _GasUsed) public {
        GasUsed = _GasUsed;
    }
       
}