/**
 *Submitted for verification at Etherscan.io on 2021-12-18
*/

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.8;

contract MessageLogger {

    event Message(bytes32 indexed topic, string message, address sender);

    function broadcast(bytes32 topic, string memory message) public {
        emit Message(topic, message, msg.sender);
    }
}