pragma solidity ^0.4.22;

contract Assignment1 {
    
    uint public studentNumber;
    address public student;
    uint public GasUsed;
    
    constructor() public {
        student = msg.sender;
    }
    
    function setStudentNumber(uint _studentNumber) public {
        studentNumber = _studentNumber;
    }
    function setGasUsed(uint _GasUsed) public {
        GasUsed = _GasUsed;
    }
}