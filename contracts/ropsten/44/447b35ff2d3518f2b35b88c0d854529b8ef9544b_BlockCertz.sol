pragma solidity ^0.5.0;

contract BlockCertz {

    uint public certID;
    address public owner;
    uint public certCount;

    struct Record {
        address studentAddress;
        string firstName;
        string lastName;
        string email;
        string school;
        string courseCode;
        string status;
        uint grade;
    }

    mapping(address => uint) public addressLookup;
    mapping(uint => Record) public recordInfo;

    constructor() public {
        owner = msg.sender;
        certID = 0;
    }

    function newRecord (address _studentAddress, string memory _fname, string memory _lname, string memory _email, string memory _school, string memory _courseCode, string memory _status, uint _grade) public {
        require(msg.sender == owner, "You are not authorized to create a new record.");
        recordInfo[certID].studentAddress = _studentAddress;
        recordInfo[certID].firstName = _fname;
        recordInfo[certID].lastName = _lname;
        recordInfo[certID].email = _email;
        recordInfo[certID].school = _school;
        recordInfo[certID].courseCode = _courseCode;
        recordInfo[certID].status = _status;
        recordInfo[certID].grade = _grade;
        addressLookup[_studentAddress] = certID;
        certID += 1;
        certCount += 1;
    }

    function updateRecord (uint _certID, address _studentAddress, string memory _fname, string memory _lname, string memory _email, string memory _school, string memory _courseCode, string memory _status, uint _grade) public {
        require(msg.sender == owner, "You are not authorized to create a new record.");
        recordInfo[_certID].studentAddress = _studentAddress;
        recordInfo[_certID].firstName = _fname;
        recordInfo[_certID].lastName = _lname;
        recordInfo[_certID].email = _email;
        recordInfo[_certID].school = _school;
        recordInfo[_certID].courseCode = _courseCode;
        recordInfo[_certID].status = _status;
        recordInfo[_certID].grade = _grade;
    }

    function deleteRecord (uint _certID) public {
        require(msg.sender == owner, "You are not authorized to delete this record.");
        recordInfo[_certID].studentAddress = address(0x0);
        recordInfo[_certID].firstName = "";
        recordInfo[_certID].lastName = "";
        recordInfo[_certID].email = "";
        recordInfo[_certID].school = "";
        recordInfo[_certID].courseCode = "";
        recordInfo[_certID].status = "";
        recordInfo[_certID].grade = 0;
        certCount -= 1;
    }

    function studentChangeRecord (uint _certID, address _newAddress, string memory _newEmail) public {
        require(msg.sender == recordInfo[_certID].studentAddress, "You are not authorized to edit this record.");
        recordInfo[_certID].studentAddress = _newAddress;
        recordInfo[_certID].email = _newEmail;
    }


    function GetRecordID (address _address) public view returns (uint) {
        return addressLookup[_address];
    }
    
    function GetRecordAddress (uint _certID) public view returns(address) {
        return recordInfo[_certID].studentAddress;
    }

    function GetFirstName (uint _certID) public view returns (string memory) {
        return recordInfo[_certID].firstName;
    }

    function GetLastName (uint _certID) public view returns (string memory) {
        return recordInfo[_certID].lastName;
    }
    function GetEmail (uint _certID) public view returns (string memory) {
        return recordInfo[_certID].email;
    }

    function GetSchool (uint _certID) public view returns (string memory) {
        return recordInfo[_certID].school;
    }

    function GetCourseCode (uint _certID) public view returns (string memory) {
        return recordInfo[_certID].courseCode;
    }

    function GetStatus (uint _certID) public view returns (string memory) {
        return recordInfo[_certID].status;
    }

    function GetGrade (uint _certID) public view returns (uint) {
        return recordInfo[_certID].grade;
    }

}