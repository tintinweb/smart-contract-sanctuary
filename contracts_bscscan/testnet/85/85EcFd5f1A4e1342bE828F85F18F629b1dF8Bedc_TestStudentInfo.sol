/**
 *Submitted for verification at BscScan.com on 2021-07-25
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract TestStudentInfo{
    
    mapping(uint256 => string) public Student;
    
    
    function setStudentInfo(string memory _stName, uint256 _stCode) public {
        Student[_stCode] = _stName;
    }
}