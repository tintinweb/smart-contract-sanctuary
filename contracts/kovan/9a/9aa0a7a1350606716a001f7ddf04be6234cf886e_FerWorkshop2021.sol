/**
 *Submitted for verification at Etherscan.io on 2021-11-08
*/

pragma solidity ^0.8.1;

contract FerWorkshop2021 {
    string[] public attendance;
    mapping (address => bool) public attended;

    function confirmAttendance(string memory name) public {
	require(!attended[msg.sender], "Student already attended");

    	attendance.push(name);
	attended[msg.sender] = true;
    }
}