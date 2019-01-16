pragma solidity ^0.4.22;

contract assignmentTwo {
    
    uint public studentNumber;
    uint public gasUsed;
    address public student;
    
    constructor() public {
        student = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == student);
        _;
    }
    
    function setStudentNumber(uint _studentNumber) external onlyOwner {
        studentNumber = _studentNumber;
    }
    
    function setGasUsed(uint _gasUsed) external onlyOwner{
        gasUsed = _gasUsed;
    }
}