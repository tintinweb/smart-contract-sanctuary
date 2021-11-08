/**
 *Submitted for verification at Etherscan.io on 2021-11-08
*/

pragma solidity ^0.8.1;

contract FerWorkshop2021 {
    mapping(address => string) public attendance;

    function confirmAttendance(string memory name) public {
    	attendance[msg.sender] = name;
    }
}