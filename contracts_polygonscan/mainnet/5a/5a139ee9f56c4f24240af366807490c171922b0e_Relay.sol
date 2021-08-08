/**
 *Submitted for verification at polygonscan.com on 2021-08-08
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Relay {
    event Message(address from, string jsonMessage);

    function message(string memory jsonMessage) public {
        emit Message(msg.sender, jsonMessage);
    }
}