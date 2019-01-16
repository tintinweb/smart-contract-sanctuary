pragma solidity ^0.4.24;
contract assignmentTwo40075764 {
    
    uint public studentNumber;
    uint public gasUsed;
    address public student;
    string public message;
    
    constructor() public {
        student = msg.sender;
        message = &#39;Thanks Professor, this subject is really interesting :D&#39;;
    }
    
    function setStudentNumber(uint _studentNumber) public {
       uint256 gasBeforeStudentNumber = gasleft();
       studentNumber = _studentNumber;
       uint256 gasLeftAfterStudentNumber = gasleft();
       setGasUsed(gasBeforeStudentNumber - gasLeftAfterStudentNumber);
    }
    
    function setGasUsed(uint _gasUsed) public{
        gasUsed = _gasUsed;
    }
}