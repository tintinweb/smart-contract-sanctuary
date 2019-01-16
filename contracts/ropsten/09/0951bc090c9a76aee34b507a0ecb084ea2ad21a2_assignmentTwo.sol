pragma solidity ^0.4.25;

contract assignmentTwo {
    uint public studentNumber;
    address public student;
    uint public GasUsed;
    
        constructor() public {
        student = msg.sender;
    }
        function setStudentNumber(uint _studentNumber) public {
          uint gasValue = gasleft();    
          studentNumber = _studentNumber;
          gasValue = gasValue - gasleft(); 
          setGasUsed(gasValue);
    }
       function setGasUsed(uint _gas) public {
           GasUsed = _gas;
       }
      }