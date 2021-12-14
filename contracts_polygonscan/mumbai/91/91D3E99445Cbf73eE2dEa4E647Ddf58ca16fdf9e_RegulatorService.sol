/**
 *Submitted for verification at polygonscan.com on 2021-12-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract RegulatorService {
    struct Permission {
        bool allowSend;
        bool allowReceive;
    }

    address public owner; // Contract owner
    mapping(address => Permission) public permissionsOf; // Whitelist

    constructor() {
        owner = msg.sender;
    }

    function check(address _from, address _to) public view returns (bool) {
        require(permissionsOf[_from].allowSend, "Sender not authorized");
        require(permissionsOf[_to].allowReceive, "Receiver not authorized");
        return true;
    }

    function setPermissions(
        address _investor,
        bool _send,
        bool _receive
    ) external returns (bool success) {
        require(
            msg.sender == owner,
            "Caller not allowed to change investor permissions"
        );
        permissionsOf[_investor].allowSend = _send;
        permissionsOf[_investor].allowReceive = _receive;
        emit Allow(_investor, Permission(_send, _receive));
        return true;
    }

    event Allow(address indexed investor, Permission indexed permission);
}