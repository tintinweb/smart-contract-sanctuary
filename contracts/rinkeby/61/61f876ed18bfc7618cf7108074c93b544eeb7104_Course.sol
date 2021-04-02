/**
 *Submitted for verification at Etherscan.io on 2021-04-01
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.7.3;

contract Course {
    string public courseName;
    address public teacher;
    address[] public students;
    mapping(address => uint32) points;
    
    constructor(string memory _name, address[] memory _students) {
        teacher = msg.sender;
        courseName = _name;
        students = _students;
    }
    
    event StudentResult(address student, uint32 points, uint date);
    
    modifier onlyTeacher() {
        require(msg.sender == teacher);
        _;
    }
    
    modifier onlyValidStudent(address _student) {
        require(studentExists(_student), "Student does not exist");
        _;
    }
    
    function addPoints(address _student, uint32 _points) public onlyTeacher onlyValidStudent(_student) {
        points[_student] += _points;
        emit StudentResult(_student, _points, block.timestamp);
    }
    
    function studentExists(address _student) public view returns (bool) {
        for (uint i = 0; i < students.length; ++i) {
            if (students[i] == _student) {
                return true;
            }
        }
        return false;
    }
    
    function getMark(address _student) public view returns (uint8) {
        uint32 studentPoints = points[_student];
        if (studentPoints < 50) { return 20; }
        if (studentPoints < 60) { return 30; }
        if (studentPoints < 70) { return 35; }
        if (studentPoints < 80) { return 40; }
        if (studentPoints < 90) { return 45; }
        return 50;
    }
}