pragma solidity ^0.4.22;

contract assignmentTwo {
    
    uint public studentNumber;
  
    uint public GasUsed;
    address public student;

    
    constructor() public {
        student = msg.sender;
        
    }
    
    function setGasUsed(uint _GasUsed) public{
        GasUsed = _GasUsed;
    }
    
    
    function setStudentNumber(uint _studentNumber) public {
        studentNumber = _studentNumber;
  
    }
       
}