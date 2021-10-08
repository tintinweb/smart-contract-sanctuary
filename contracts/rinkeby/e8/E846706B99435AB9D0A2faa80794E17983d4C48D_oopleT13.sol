/**
 *Submitted for verification at Etherscan.io on 2021-10-07
*/

// SPDX-License-Identifier: GPL-3.0


/*
This Smart Contract was made for a Discord bot to use.
*/

pragma solidity >=0.7.0 <0.9.0;

contract oopleT13 {
    struct User {
        uint id;
        uint discordId;
        uint balance;
        bool isAdmin;
    }

    mapping(uint => uint) public discordIdToId;
    
    User[] public userbase;
    address private bot;

    constructor() {
            bot = msg.sender;
            userbase.push(User(1, 516304238893203487, 420, true));
            discordIdToId[516304238893203487] = 1;
        }   
    
    modifier onlyBot() {
        require(msg.sender == bot, "You must be the Contract owner/Discord bot.");
        _;
    }

    function addUser(uint _discordId, uint _balance, bool _isAdmin) public onlyBot {
        userbase.push(User((userbase.length + 1), _discordId, _balance, _isAdmin));
        discordIdToId[_discordId] = userbase.length;
    }
    
    function removeUser(uint _userId) public onlyBot {
        for (uint i = _userId-1; i < userbase.length-1; i++) {
            userbase[i] = userbase[i+1];
        }
        userbase.pop;
    }

    function pay(uint _amount, uint _toId) public onlyBot {
        userbase[(_toId - 1)].balance += _amount;
    }

    function send(uint _amount, uint _toId, uint _fromId) public onlyBot {
        userbase[(_fromId - 1)].balance -= _amount;
        userbase[(_toId - 1)].balance += _amount;
    }
    
    function checkBalance(uint _id) public view returns (uint) {
        return userbase[(_id - 1)].balance;
    }
    
    function viewBotAddress() public view returns (address) {
        return bot;
    }
}