/**
 *Submitted for verification at Etherscan.io on 2021-10-06
*/

// SPDX-License-Identifier: GPL-3.0



pragma solidity >=0.7.0 <0.9.0;

contract oopleT7 {
    struct User {
        uint id;
        uint discordId;
        uint balance;
        bool isAdmin;
    }

    User[] public userbase;
    address private bot;

    constructor() {
            bot = msg.sender;
            userbase.push(User(1, 516304238893203487, 1000, true));
        }   
    
    modifier onlyBot() {
        require(msg.sender == bot, "You must be the Contract owner.");
        _;
    }

    function addUser(uint _discordId, uint _balance, bool _isAdmin) public onlyBot {
        userbase.push(User((userbase.length + 1), _discordId, _balance, _isAdmin));
    }

    function send(uint _amount, uint _to, uint _from) public {
        /*require(userbase[(_from + 1)].balance > 0, "You must send at least 1 oopleCoin.");
        require(_amount <= userbase[(_from + 1)].balance, "You can not send more then your balance.");
        require(_to <= userbase.length, "The wallet id you are sending oopleCoin to, must exist.");
        require(_from > 0, "There is no wallet id below 1");*/
        userbase[(_from + 1)].balance -= _amount;
        userbase[(_to + 1)].balance += _amount;
    }
    
    function checkBalance(uint _id) public view returns (uint) {
        return userbase[(_id - 1)].balance;
    }
    
    function viewBotAddress() public view returns (address){
        return bot;
    }
}