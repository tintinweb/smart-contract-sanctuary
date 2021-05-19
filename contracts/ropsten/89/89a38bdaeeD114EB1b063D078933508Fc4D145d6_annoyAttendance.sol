/**
 *Submitted for verification at Etherscan.io on 2021-05-19
*/

pragma solidity ^0.5.16;

contract annoyAttendance {

    mapping(address => bool) attendees;
    uint256 count;

    function signIn() external payable {
        require(attendees[msg.sender] == false, 'Address already sign in.');
        require(msg.value == 0.1 ether,'Send more than 0.1 ETH to sign in.');
        attendees[msg.sender] = true;
        count++;
    }

    function signOut() external {
        require(attendees[msg.sender] == true,'Address already sign out.');
        msg.sender.transfer(0.1 ether); // ?
        attendees[msg.sender] = false;
        count--;
    }

    function checkAttendee(address  _address) external view returns(bool) {
        return attendees[_address];
    }

    function getAttendeeCount() external view returns(uint) {
        return count;
    }

}