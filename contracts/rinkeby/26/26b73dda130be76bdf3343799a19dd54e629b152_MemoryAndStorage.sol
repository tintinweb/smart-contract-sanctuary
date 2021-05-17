/**
 *Submitted for verification at Etherscan.io on 2021-05-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.5;

contract MemoryAndStorage {
    mapping(uint256 => User) users;
    struct User {
        uint256 id;
        uint256 balance;
    }

    constructor() {}

    function addUser(uint256 id, uint256 balance) public {
        users[id] = User(id, balance);
    }

    function updateBalance(uint256 id, uint256 balance) public {
        users[id].balance=balance;
        
    }

    function getBalance(uint256 id) public view returns (uint256) {
        return users[id].balance;
    }
}