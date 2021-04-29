/**
 *Submitted for verification at Etherscan.io on 2021-04-29
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract hello {
    
    mapping(address => bool) public students;
    address[] public studentsAddress;
    uint public headCount;
    address teacher;
    
    event NewStudent(address student);
    
    constructor() {
        teacher = msg.sender;
    }
    
    function sayHi() public {
        if (!students[msg.sender] != true) {
            revert("Already counted!");
        }
        students[msg.sender] = true;
        studentsAddress.push(msg.sender);
        headCount++;
        emit NewStudent(msg.sender);
    }
    
    function listStudents() public view returns (address[] memory) {
        return studentsAddress;
    }

    
}