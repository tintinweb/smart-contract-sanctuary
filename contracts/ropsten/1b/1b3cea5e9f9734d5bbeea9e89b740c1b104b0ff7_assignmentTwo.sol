pragma solidity ^0.4.22;

contract assignmentTwo {
    
    uint public studentNumber;
    uint public GasUsed;
    address public student;

    function setStudentNumber(uint _studentNumber) public {
        studentNumber = _studentNumber;
    }
    function GasUsed(uint _GasUsed) public {
        GasUsed = _GasUsed;
    }
       
}