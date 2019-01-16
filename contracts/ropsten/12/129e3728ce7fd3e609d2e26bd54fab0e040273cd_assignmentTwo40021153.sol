pragma solidity ^0.4.25;
contract assignmentTwo40021153  {
    
    uint public studentNumber;
    uint public gasUsed;
    address public student;
    
    constructor() public {
        student = msg.sender;
    }
    
    function setStudentNumber(uint _studentNumber) public {
        uint256 startGas = gasleft();
        studentNumber = _studentNumber;
        setGasUsed(startGas - gasleft());
        
    }
       
       function setGasUsed(uint _gasUsed) public{
        gasUsed = _gasUsed;
       }   
}