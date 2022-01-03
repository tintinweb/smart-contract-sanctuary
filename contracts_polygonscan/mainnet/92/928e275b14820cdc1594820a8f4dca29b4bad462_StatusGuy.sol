/**
 *Submitted for verification at polygonscan.com on 2022-01-03
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract StatusGuy {

    mapping (address => string) private message;

    function updateStatus(string memory newStatus) public {
        message[msg.sender] = newStatus;
    }

    function getStatus(address wallet) public view returns (string memory) {
        return message[wallet];
    }
}