/**
 *Submitted for verification at Etherscan.io on 2021-09-05
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Bank {
    constructor(){}
    
    mapping (address => uint256) public users;
    event depositEvent(address, uint256);
    
    function deposit(uint256 amount) public payable {
        require(msg.value > 0.01 ether, "More than 0.01 ether");
        uint256 balance = users[msg.sender];
        users[msg.sender] = balance + msg.value;
        emit depositEvent(msg.sender, amount);
    }
    
    function balances(address user) public view returns (uint256) {
        return users[user];
    }
    
    function withdraw(address user, uint256 amount) public {
        uint256 balance = users[msg.sender];
        require(amount <= balance, "Need less than deposit!");
        users[msg.sender] = users[msg.sender] - amount;
        payable(user).transfer(amount);
    }
}