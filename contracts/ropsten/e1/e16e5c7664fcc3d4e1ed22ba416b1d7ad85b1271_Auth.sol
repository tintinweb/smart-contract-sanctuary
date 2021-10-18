/**
 *Submitted for verification at Etherscan.io on 2021-10-18
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Auth {

    // THESE EVENTS ARE EMITTED WHEN USERS GET ADDED / REMOVED
    event Added(address user);
    event Removed(address user);

    // CONTRACT STORAGE MAPPING ADDRESSES TO STATUS
    mapping(address => bool) private users;

    // USERS CAN ADD THEMSELVES BY CALLING THIS FUNCTION
    function add () external {
        users[msg.sender] = true;
        emit Added(msg.sender);
    }

    // USERS CAN REMOVE THEMSELVES BY CALLING THIS FUNCTION
    function remove () external {
        users[msg.sender] = false;
        emit Removed(msg.sender);
    }

    // FUNCTION TO CHECK ANY ADDRESS STATUS BY ANYONE
    function check (address user) external view returns (bool) {
        return users[user];
    }
}