/**
 *Submitted for verification at Etherscan.io on 2021-12-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CRUD01 {
    struct User {
        uint256 id;
        string name;
    }

    User[] public users;
    uint256 public nextId;

    function create(string memory _name) public {
        users.push(User(nextId, _name));
        nextId++;
    }

    function read(uint256 _id) public view returns (uint256, string memory) {
        for (uint256 i = 0; i < users.length; i++) {
            if (users[i].id == _id) {
                return (users[i].id, users[i].name);
            }
        }

        revert("User does not exit!");
    }

    function totalUsers() public view returns (User[] memory) {
        return users;
    }
}