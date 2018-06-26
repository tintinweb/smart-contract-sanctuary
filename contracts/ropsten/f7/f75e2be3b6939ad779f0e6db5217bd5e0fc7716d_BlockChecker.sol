pragma solidity ^0.4.24;
contract Owned {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}
contract Course is Owned {
    mapping (address => bool) public approved;
    mapping (address => bool) public requested;
    mapping (address => mapping (int => bool)) userChecks;
    
    string public name;
    
    uint public minimumAllowed = 0;
    uint public maximumAllowed = 0;

    event RequestedAccess(address User);
    event ApprovedAccess(address User);
    
    constructor(address newOwner, string newName) public {
        owner = newOwner;
        name = newName;
    }
    
    function requestAccess() public {
        requested[msg.sender] = true;
        emit RequestedAccess(msg.sender);
    }
    
    function approveAccess(address toApprove) onlyOwner public {
        require(requested[toApprove]);
        approved[toApprove] = true;
        requested[toApprove] = false;
        emit ApprovedAccess(toApprove);
    }
    
    function raiseNumberOfCheckmarks(uint newMax) onlyOwner {
        require(newMax > maximumAllowed);
        maximumAllowed = newMax;
    }
    function forbidChecking(uint newMin) onlyOwner {
        require(newMin > minimumAllowed);
        minimumAllowed = newMin;
    }
    
    
    
}

contract Register {
    mapping(address => string) public userNames;
    uint public numberOfUsers;

    event RegisterSuccess(address user, string name);

    function Register() public {
        numberOfUsers = 0;
    }

    function registerUser(string userName) public {
        require(bytes(userNames[msg.sender]).length == 0);
        require(bytes(userName).length > 0);
        userNames[msg.sender] = userName;
        numberOfUsers++;
        RegisterSuccess(msg.sender, userName);
    }

}
contract BlockChecker is Owned, Register {
    uint public numberOfCourses = 0;
    mapping (uint => Course) public courses;
    
    event CourseCreated(address from, address courseAddress);
    
    constructor() public {
        
    }
    
    function createCourse(string name) public {
        require(bytes(name).length > 0);
        Course course = new Course(msg.sender, name);
        courses[numberOfCourses] = course;
        numberOfCourses++;
        emit CourseCreated(msg.sender, address(course));
    }
}