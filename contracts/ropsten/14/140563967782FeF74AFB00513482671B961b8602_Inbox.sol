/**
 *Submitted for verification at Etherscan.io on 2021-11-26
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.21;

contract Inbox {
    string public message;

    event newMessage(string message);

    function get() public view returns (string memory) {
        return message;
    }

    function set(string memory _message) public {
        message = _message;
        emit newMessage(message);
    }
}