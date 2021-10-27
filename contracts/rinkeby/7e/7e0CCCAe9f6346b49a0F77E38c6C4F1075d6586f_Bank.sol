/**
 *Submitted for verification at Etherscan.io on 2021-10-27
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

contract Bank {
    uint256 private balance;

    constructor (uint256 _initBalance) {
        balance = _initBalance;
    }

    function getBalance() public view returns (uint256) {
        return balance;
    }

    function deposit(uint256 _amount) public returns (bool success) {
        balance += _amount; 
        return true;
    }

    function withdraw(uint256 _amount) public returns (bool success) {
        require(balance >= _amount, "not enough amount to withdraw");
        balance -= _amount;
        return true;
    }
}