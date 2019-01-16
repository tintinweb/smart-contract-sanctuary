pragma solidity ^0.4.22;

contract assignmentTwo {
    
    uint public studentNumber;
    address public student;
    uint256 public gasUsed;
    
    constructor() public {
        student = msg.sender;
    }
    
    function setStudentNumber(uint _studentNumber) public {
        uint256 gasleftBeforeSettingStudentNumber;
        gasleftBeforeSettingStudentNumber = gasleft();
        studentNumber = _studentNumber;
        setGasUsed(gasleftBeforeSettingStudentNumber - gasleft());
    }
    
    function setGasUsed(uint _gasUsed) public {
        gasUsed = _gasUsed;
    }  
}