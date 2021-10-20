/**
 *Submitted for verification at Etherscan.io on 2021-10-19
*/

pragma solidity ^0.8.0;

contract ACM {
    
    uint256 public numStudents;
    
    constructor(uint256 _students) {
        numStudents = _students;
    }
    
    function getNumStudents() public view returns (uint256) {
        return numStudents;
    }
    
    function setNumStudents(uint256 _students) public {
        numStudents = _students;
    }
    
}