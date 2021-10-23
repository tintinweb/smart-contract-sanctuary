/**
 *Submitted for verification at Etherscan.io on 2021-10-22
*/

pragma solidity ^0.8.0;

contract ACM_Presentation {
    
    uint attendance;
    
    constructor(uint _numAttendees) {
        attendance = _numAttendees;
    }
    
    function getAttendance() public view returns (uint) {
        return attendance;
    }
    
    function setAttendance(uint _new_attendance) public {
        attendance = _new_attendance;
    }
    
}