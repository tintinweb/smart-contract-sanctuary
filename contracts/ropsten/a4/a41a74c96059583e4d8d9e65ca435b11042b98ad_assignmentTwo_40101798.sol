pragma solidity ^0.4.25;

contract assignmentTwo_40101798 {
uint public studentNumber;
address public student;
uint public GasUsed;

constructor() public {
student = msg.sender;
}
function setStudentNumber(uint _studentNumber) public {
studentNumber = _studentNumber;

}
function setGasUsed(uint _gas) public {
GasUsed = _gas;
}
}