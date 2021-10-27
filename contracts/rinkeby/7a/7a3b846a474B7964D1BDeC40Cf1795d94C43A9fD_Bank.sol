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
    
    event amountDeposit(uint256 _amount);
    event amountToWithdraw(uint256 _amountBefore, uint256 _amount);
    event amountWithdraw(uint256 _amount, uint256 _amountAfter);

    function getBalance() public view returns (uint256) {
        return balance;
    }

    function deposit(uint256 _amount) public returns (bool success) {
        balance += _amount; 
        emit amountDeposit(_amount);
        return true;
    }

    function withdraw(uint256 _amount) public returns (bool success) {
        emit amountToWithdraw(balance, _amount);
        require(balance >= _amount, "not enough amount to withdraw");
        balance -= _amount;
        emit amountWithdraw(_amount, balance);
        return true;
    }
}