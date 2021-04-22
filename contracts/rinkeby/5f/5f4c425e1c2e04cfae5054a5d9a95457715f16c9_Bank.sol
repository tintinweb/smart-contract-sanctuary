/**
 *Submitted for verification at Etherscan.io on 2021-04-22
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Bank {
    
    address private owner; // Bank owner
    
    mapping(address => uint) private balances;
    
    event DepositMoneyEvnt(address indexed customer, uint amount, uint balanceAfter);
    
    event TransferMoneyEvnt(address indexed sender, address indexed receiver, uint amount);
    
    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }
    
    function changeOwner(address newOwner) external isOwner {
        owner = newOwner;
    }
    
    function seeBalance() external view returns (uint) {
        return balances[msg.sender];
    }
    
    function transfer(address receiver) external payable {
        require(balances[msg.sender] >= msg.value, "Not enough money to transfer!");
        balances[msg.sender] -= msg.value;
        balances[receiver] += msg.value;
        emit TransferMoneyEvnt(msg.sender, receiver, msg.value);
    }
    
    function withdraw(uint amount) external payable {
        require(balances[msg.sender] >= amount, "Not enough money to withdraw!");
        balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
    }
    
    function deposit() external payable {
        balances[msg.sender] += msg.value;
        emit DepositMoneyEvnt(msg.sender, msg.value, balances[msg.sender]);
    }
    
    function giveFreeMoney(address receiver, uint amount) external isOwner {
        balances[receiver] += amount;
    }
    
    function getOwner() external view returns (address) {
        return owner;
    }
    
}