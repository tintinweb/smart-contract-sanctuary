/**
 *Submitted for verification at Etherscan.io on 2021-10-16
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract Crud {
    struct User {
        uint id;
        string name;
    }
    User[] public users;
    uint public nextId;
    
    function create(string memory name) public {
        users.push(User(nextId, name));
        ++nextId;
    }
    
    function read(uint id) view public returns(uint, string memory) {
        uint index = find(id);
        return (users[index].id, users[index].name);
    }
    
    function update(uint id, string memory name) public {
        uint index = find(id);
        users[index].name = name;
    }
    
    function deleteUser(uint id) public {
        uint index = find(id);
        delete users[index];
    }
    
    function find(uint id) view internal returns(uint) {
        for(uint i = 0; i < users.length; i++) {
            if(users[i].id == id) {
                return i;
            }
        }
        revert('User does not exits');
    }
}