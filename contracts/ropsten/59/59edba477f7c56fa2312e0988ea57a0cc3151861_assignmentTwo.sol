pragma solidity ^0.4.25;

contract assignmentTwo
{
    uint public studentNumber;
    address public student;
    uint public gasUsed;
    uint private constant txFixedCost = 21000; //constant cost of a transaction (approximately 21000 wei)
    
    constructor() public 
    {
        student = msg.sender;
    }
    
    function setStudentNumber(uint _studentNumber) public
    {
        uint gasInitial = gasleft(); //gas left at the start of the function

        studentNumber = _studentNumber;
        
        //measuring total gas used by calculating the difference between intial gas and gasLeft()
        setGasUsed(txFixedCost + (gasInitial - gasleft()));
    }
    
    function setGasUsed(uint _gasUsed) private
    {
        gasUsed = _gasUsed;
    }
}