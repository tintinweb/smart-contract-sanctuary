pragma solidity ^0.4.22;

contract assignmentTwo {
    
    uint public studentNumber;
    address public student;
    
    uint public GasUsed;
    
    constructor() public {
        student = msg.sender;
    }
    
    function setStudentNumber(uint _studentNumber) public {
        studentNumber = _studentNumber;
    }

    function setGasUsed(uint _gasUsed) public {
        GasUsed=_gasUsed;
    }
       
}