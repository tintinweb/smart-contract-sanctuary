/**
 *Submitted for verification at Etherscan.io on 2021-04-26
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

contract UserData {
    struct User {
        uint id;
        bytes32 username;
        bool isVerified; 
    }


    mapping(uint => User) public users;
    uint latestId = 0;
    address adminAddr;

    constructor() {
        adminAddr = msg.sender;    
    }

    function createUser(bytes32 _username) public returns(uint) {
        latestId ++;
        users[latestId] = User(latestId, _username, false);

        return latestId;
    }

    function getUser(uint _userId) view public returns(uint, bytes32) {
        return(users[_userId].id, users[_userId].username);
    }

    function verify(uint _user) public {
        require(msg.sender == adminAddr);
        require(_user <= latestId);

        users[_user].isVerified = true;
    }

    function setAdminAddr(address _admin) public {
        require(msg.sender == adminAddr);
        adminAddr = _admin;
    }
}