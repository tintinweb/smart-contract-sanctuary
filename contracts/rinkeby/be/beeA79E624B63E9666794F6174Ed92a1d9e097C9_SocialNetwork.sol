// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract SocialNetwork {

    event NewStatus(string _statusMessage, address indexed _sender);

    /**
     * Function to post a new status on the Ethereum Social Network wall
     *
     * @param _statusMessage - String to represent status
     *
     * No return, reverts on error
    */
    function post(string memory _statusMessage) public {
        emit NewStatus(_statusMessage, msg.sender);
    }
}

