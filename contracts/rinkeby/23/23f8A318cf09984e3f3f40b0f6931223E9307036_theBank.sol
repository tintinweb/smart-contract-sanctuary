/**
 *Submitted for verification at Etherscan.io on 2021-11-13
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract theBank {

    uint public total_accounts;
    
    mapping(address => uint) private user_to_account;
    
    mapping(uint => uint) private account_to_balance;
    
    modifier hasAccount {
        require(user_to_account[msg.sender] != 0, "You must create a Joint Account first!");
        _;
    }
    
    constructor() {
        
    }
    
    function start_joint_account(address payable _secondUser) payable public {
        require(user_to_account[msg.sender] == 0, "You may only have one Joint Account per address.");
        require(user_to_account[_secondUser] == 0, "The second user is already part of a Joint Account.");
        require(_secondUser != msg.sender, "The second user cannot be yourself.");
        require(msg.value >= 10000000000000000, "Must deposit at least 0.01 eth, to start an Joint Account.");
        uint uid = total_accounts + 1;
        total_accounts += 1;
        user_to_account[msg.sender] = uid;
        user_to_account[_secondUser] = uid;
        account_to_balance[uid] = uint(msg.value);
    }
    
    function deposit() payable public hasAccount {
        account_to_balance[user_to_account[msg.sender]] += msg.value;
    }
    
    function withdrawl(uint _weiToWithdrawl) public hasAccount {
        uint user_balance = account_to_balance[user_to_account[msg.sender]];
        require(_weiToWithdrawl <= user_balance);
        account_to_balance[user_to_account[msg.sender]] -= _weiToWithdrawl;
        payable(msg.sender).transfer(_weiToWithdrawl);
    }
    
    function view_balance(address _addy) view public returns(uint) {
        return account_to_balance[user_to_account[_addy]];
    }
    
}