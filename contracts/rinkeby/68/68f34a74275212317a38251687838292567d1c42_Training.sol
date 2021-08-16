/**
 *Submitted for verification at Etherscan.io on 2021-08-15
*/

pragma solidity ^0.4.18;

contract Training {

    address owner;
    string participationUrl;
    uint studentLimit;
    uint registeredUserCount;
    bool isActive;
    mapping(address => Student) students;
    mapping(uint => address) studentsIndex;

    struct Student {
        string email;
        bool validated;
        address addr;
        bool deleted;
    }

    event StudentRegistered(address addr, string email);

    modifier onlyOwner() {
        require(owner == msg.sender);
        _;
    }

    modifier onlyActive() {
        require(isActive);
        _;
    }

    function Training(uint _studentLimit) public {
        owner = msg.sender;
        isActive = true;

        if (_studentLimit != 0) {
            studentLimit = _studentLimit;
        } else {
            studentLimit = 30;
        }
    }

    /* Student Functions */

    function registerToEvent(string email) onlyActive public {
        require(!isRegistered(msg.sender));
        require(registeredUserCount < studentLimit);

        registeredUserCount++;
        students[msg.sender] = Student(email, false, msg.sender, false);
        studentsIndex[registeredUserCount] = msg.sender;

        StudentRegistered(msg.sender, email);
    }

    function isRegistered(address _addr) public constant returns (bool) {
		return students[_addr].addr != address(0) && !students[_addr].deleted;
	}

	function getMeParticipationUrl() public constant returns (string) {
	    require(isRegistered(msg.sender));
	    Student storage student = students[msg.sender];
	    require(student.validated);
	    return participationUrl;
	}

    function getTotalCount() public constant returns (uint) {
        return registeredUserCount;
    }

    function getStudentLimit() public constant returns (uint) {
        return studentLimit;
    }

	/* Admin Functions */

	function getStudent(uint idx) public constant onlyOwner returns (uint index, string email, address addr) {
	    address studentAddr = studentsIndex[idx];
	    Student storage student = students[studentAddr];
	    return (idx, student.email, student.addr);
	}

    function deleteStudent(uint idx) public onlyOwner {
        address studentAddr = studentsIndex[idx];
        Student storage student = students[studentAddr];
        student.deleted = true;
        registeredUserCount--;
    }

	function validateStudentStatus(uint idx, bool isValidated) public onlyOwner {
	    address studentAddr = studentsIndex[idx];
	    Student storage student = students[studentAddr];
	    student.validated = isValidated;
	}

	function setParticipationLink(string url) public onlyOwner {
	    participationUrl = url;
	}

	function closeParticipation() public onlyOwner {
	    isActive = false;
	}

    function openParticipation() public onlyOwner {
        isActive = true;
    }
}