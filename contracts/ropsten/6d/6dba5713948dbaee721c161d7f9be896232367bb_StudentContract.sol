/**
 *Submitted for verification at Etherscan.io on 2021-09-06
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

contract StudentContract {
    uint256 internal studentCount = 0;

    // Struct to store data of users.
    struct StudentInfo {
        string name;
        uint256 age;
        string IdentityCard;
        string FathersInitial;
        string DateOfBirth;
        string MailingAddress;
        uint256 PhoneNumber;
        string Country;
        string Nationality;
    }

    StudentInfo[] internal StudentInfoArray;
    string[] internal OtherArray;
    address payable public Owner;
    mapping(address => uint256) internal students;

    event SetData(string message);

    constructor() {
        Owner = payable(msg.sender);
    }

    function setData(
        string memory _name,
        uint256 _age,
        string memory _IdentityCard,
        string memory _FathersInitial,
        string memory _DateOfBirth,
        string memory _MailingAddress,
        uint256 _PhoneNumber,
        string memory _Country,
        string memory _Nationality
    ) public returns (uint256) {
        /*require(students[msg.sender] == 0, "Data already exist for this wallet");*/

        StudentInfo memory tx1 = StudentInfo(
            _name,
            _age,
            _IdentityCard,
            _FathersInitial,
            _DateOfBirth,
            _MailingAddress,
            _PhoneNumber,
            _Country,
            _Nationality
        );
        StudentInfoArray.push(tx1);
        studentCount++;
        students[msg.sender] = studentCount;

        emit SetData("Congratulations you have set your data");

        return studentCount;
    }

    modifier onlyOwner() {
        require(Owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function setNewName(string memory _name) public returns (bool success) {
        uint256 studentId = students[msg.sender];
        StudentInfo storage newStudent = StudentInfoArray[studentId - 1];
        newStudent.name = _name;
        return true;
    }

    function setNewMail(string memory _MailingAddress)
        public
        returns (bool success)
    {
        uint256 studentId = students[msg.sender];
        StudentInfo storage newStudent = StudentInfoArray[studentId - 1];
        newStudent.MailingAddress = _MailingAddress;
        return true;
    }

    function getStudentData() public view returns (StudentInfo memory) {
        StudentInfo memory tx1 = StudentInfoArray[students[msg.sender] - 1];
        return tx1;
    }
}