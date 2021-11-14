/**
 *Submitted for verification at Etherscan.io on 2021-11-13
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract theBank {

    struct Joint_Account {
        string name;
        uint balance;
    }
    
    Joint_Account[] private jointAccounts;
    
    mapping(address => uint) private is_authorized_to_uid;
    
    modifier hasAccount {
       require(is_authorized_to_uid[msg.sender] != 0, "You must create a Joint Account first!");
       _;
    }
    
    constructor() {
        jointAccounts.push(Joint_Account("0x0", 0));
    }
    
    function start_joint_account(string memory _name, address payable _secondUser) payable public{
        require(is_authorized_to_uid[msg.sender] == 0, "You may only have one Joint Account per address.");
        require(_secondUser != msg.sender, "The second user cannot be yourself.");
        require(msg.value >= 10000000000000000, "Must deposit at least 0.01 eth, to start an Joint Account.");
        jointAccounts.push(Joint_Account(_name, uint(msg.value)));
        is_authorized_to_uid[msg.sender] = jointAccounts.length - 1;
        is_authorized_to_uid[_secondUser] = jointAccounts.length - 1;
    }
    
    function deposit() payable public hasAccount {
        jointAccounts[is_authorized_to_uid[msg.sender]].balance += msg.value;
    }
    
    function withdrawl(uint _weiToWithdrawl) public hasAccount {
        uint user_balance = jointAccounts[is_authorized_to_uid[msg.sender]].balance;
        require(_weiToWithdrawl <= user_balance);
        jointAccounts[is_authorized_to_uid[msg.sender]].balance -= _weiToWithdrawl;
        payable(msg.sender).transfer(_weiToWithdrawl);
    }
    
    function view_balance(address _addy) view public returns(uint) {
        return uint(jointAccounts[is_authorized_to_uid[_addy]].balance);
    }
    
}