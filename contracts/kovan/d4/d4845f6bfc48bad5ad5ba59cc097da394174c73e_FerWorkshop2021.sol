/**
 *Submitted for verification at Etherscan.io on 2021-11-09
*/

pragma solidity ^0.8.1;

contract FerWorkshop2021 {
    mapping (address => bool) public attended;
    string[] public attendance;

    function confirmAttendance(string memory name) public {
	require(!attended[msg.sender], "Student already attended");

    	attendance.push(name);
	attended[msg.sender] = true;
    }
}