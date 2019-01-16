pragma solidity ^0.5.0;

contract assignmentTwo {
    
    uint public studentNumber;
    uint public GasUsed;
    address public student;
    constructor() public {
        student = msg.sender;
    }
    
   
    
    function setStudentNumber(uint _studentNumber) public {
        
        studentNumber = _studentNumber;
    }
    
    
    
    function setter(uint _Value) public {
        
        GasUsed = _Value;
        
    }
}