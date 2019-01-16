pragma solidity ^0.4.24;

contract Assignment2 {
    
    uint public studentNumber;
    address public student;
    uint public gasused;
    
    constructor() public {
        student = msg.sender;
    }
    
    function setStudentNumber(uint _studentNumber) public {
        
        studentNumber = _studentNumber;
    }
    
    function setGasUsed(uint _gasused)public {
        gasused=_gasused;
    }
}