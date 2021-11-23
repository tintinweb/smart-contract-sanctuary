/**
 *Submitted for verification at BscScan.com on 2021-11-22
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Bank {
    
    mapping(address => uint) _balances;
    event Deposit(address indexed owner, uint amount);
    event Withdraw(address indexed owner, uint amount);
    
    function deposit() public payable {
        require(msg.value > 0, "Can't Deposit");
        _balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }
    
    function withdraw(uint amount) public payable {
        require(amount > 0 && amount >= _balances[msg.sender], "Not enough Money");
        payable(msg.sender).transfer(amount);
        _balances[msg.sender] -= amount;
        emit Withdraw(msg.sender, amount);
    }
    function checkBalances()public view returns (uint balance){
        return _balances[msg.sender];
    }
    function balanceOf(address owner) public view returns (uint balance){
        return _balances[owner];
    }
    
}