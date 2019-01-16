pragma solidity ^0.4.22;

contract assignmentTwo {
    uint public studentNumber;
    uint public GasUsed;
    address public student;
    
    constructor() public {
        student = msg.sender;
    }
    
    modifier calculateGas() {
        uint beforeCallGas = gasleft();
        _;
        setGasUsed(beforeCallGas - gasleft());
    }
    
    function setStudentNumber(uint _studentNumber) public calculateGas {
        studentNumber = _studentNumber;
    }
    
    function setGasUsed(uint _gasUsed) private {
        GasUsed = _gasUsed;
    }
}