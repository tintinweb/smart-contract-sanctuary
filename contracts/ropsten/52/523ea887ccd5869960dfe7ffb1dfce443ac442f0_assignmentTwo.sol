pragma solidity ^0.4.24;

contract assignmentTwo {
    uint public gasUsed;
    uint public studentNumber;
    uint private _myContractGasUsed=22344;
    //I calculated the gas used manually by my contract (per operation //transaction using testing and web)
    address public student;
    constructor() public 
    {
        
       student = msg.sender;
    }
    
    function setStudentNumber(uint _studentNumber) public 
    {
      gasUsed=gasleft();
      studentNumber = _studentNumber;
      setGasUsed();
      
    }
    function setGasUsed() public 
    {
        gasUsed= (gasUsed - gasleft())+ _myContractGasUsed;
    }
    
}