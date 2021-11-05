//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract AccessClassrooms {
    //@dev keeps track of the classroom capacities 
	mapping(uint256 => uint256) classroomCapacity;
	//@dev keeps track of the number of student currently in a classroom
	mapping(uint256 => uint256) numStudentsInClassroom;
	//@dev keeps track of where an individual student is. 
	mapping(address => uint256) studentInClassroom;
	mapping(address => uint256[]) datesForClassrooms;
	mapping (address => uint256[]) classroomForStudents;
	uint256[] private classroomsVisited;
	address admin;
	modifier onlyAdmin {
	    require(msg.sender == admin);
	    _;
	}
	constructor() {
	    admin = msg.sender;
	}
	//@dev registers a student entering a classroom. 
	function enterClassroom(uint256 classroomID) public {
	    require(studentInClassroom[msg.sender] == 0, "enterClassroom: can't be in multiple classrooms at once");
	    // @dev Will also revert here if the classroom doesnt exist. 
	    require(classroomCapacity[classroomID] > numStudentsInClassroom[classroomID], "enterClassroom: classroom already full");
	    studentInClassroom[msg.sender] = classroomID;
	    numStudentsInClassroom[classroomID]++;
	    uint256 length = classroomForStudents[msg.sender].length;
	    classroomForStudents[msg.sender][length] = classroomID;
	    // @dev records the date in unix days (the number of days passed since january 1st 1970)
	    datesForClassrooms[msg.sender][length] = block.timestamp / 1 days; 
	}
	//@dev registers a student leaving  a classroom. 
	function leaveClassroom() public {
	    require(studentInClassroom[msg.sender] != 0, "leaveClassroom: student not currently in any classroom");
	    numStudentsInClassroom[studentInClassroom[msg.sender]]--;
	    studentInClassroom[msg.sender] = 0;
	}
	//@dev returns the student current location, 0 meaning he's not in a classroom. 
	function studentLocation(address student) public view returns(uint256 classroomID) {
	    return studentInClassroom[student];
	}
	function studentInClassroomAtDate(address student, uint256 date, uint256 classroomID) public view returns(bool) {
	    bool studentFound;
	    for(uint256 i; i < classroomForStudents[student].length; i++) {
	        if (classroomForStudents[student][i] == classroomID) {
	            if (datesForClassrooms[student][i] == date) {
	                studentFound = true;
	                break;
	            }
	        }
	    }
	    return studentFound;
	}
	// Setting capacity to 0 effectively deletes the classroom. 
	function setClassroom(uint256 classroomID, uint256 capacity) public onlyAdmin {
	    //@dev design descision, 0 means "no classroom". There are other ways to do it ig but i went with this. 
	    require(classroomID != 0, "setClassroom: can't set a classroom to ID 0. ");
        classroomCapacity[classroomID] = capacity;	    
	}
	function setAdmin(address newAdmin) public onlyAdmin {
	    admin = newAdmin;
	}
}