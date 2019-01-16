pragma solidity ^0.5.0;



contract assignmentTwo {

    

    uint public studentNumber;

    address public student;
	uint public gasused;

    

    constructor() public {

        student = msg.sender;

    }

    

    function setStudentNumber(uint _studentNumber) public {

        studentNumber = _studentNumber;

    }
	
	function setGasUsed (uint _gasused) public {
	
	gasused = _gasused;
	
	}

       

}