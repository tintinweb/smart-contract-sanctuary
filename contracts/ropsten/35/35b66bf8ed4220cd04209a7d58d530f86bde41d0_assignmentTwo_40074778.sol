pragma solidity ^0.4.24;

contract assignmentTwo_40074778 {
    
uint public studentNumber;
address public student;

uint public GasUsed;
address public gas;

constructor() public {
student = msg.sender;
gas = msg.sender;
}


function setStudentNumber(uint _studentNumber) public {
studentNumber = _studentNumber;

}

function setgasUsed(uint _GasUsed) public {
    GasUsed = _GasUsed;
}
}