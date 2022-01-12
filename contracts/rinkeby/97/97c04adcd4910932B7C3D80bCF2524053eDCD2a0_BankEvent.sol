/**
 *Submitted for verification at Etherscan.io on 2022-01-11
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract BankEvent {

    mapping(address => uint) _balances;

    // Event for focus filter
    event Deposit(address indexed owner, uint amount);
    event Withdraw(address indexed owner, uint amount);

    // payable for transfer
    function deposit() public payable {
        require(msg.value > 0, "deposit money is zero");

        // Update balance
        _balances[msg.sender] += msg.value;

        // Emit event
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint amount) public {
        require(amount > 0 && amount <= _balances[msg.sender], "not enough mooney");

        // msg.sender <- trannsfer
        payable(msg.sender).transfer(amount);

        // Update balance
        _balances[msg.sender] -= amount;

        // Emit event
        emit Withdraw(msg.sender, amount);
    }

    function balance() public view returns(uint) {
        return _balances[msg.sender];
    }

    function balanceOf(address owner) public view returns(uint) {
        return _balances[owner];
    }
}