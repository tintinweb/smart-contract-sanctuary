/**
 *Submitted for verification at Etherscan.io on 2021-08-26
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.4;

contract DepositWithdrawal {
    mapping(address=> uint) public deposits;
    uint public totalDeposits = 0;
    
    // Deposit Function
    function deposit() public payable {
        deposits[msg.sender] = deposits[msg.sender] + msg.value;
        totalDeposits = totalDeposits + msg.value;
    }
    
    // Withdraw Function
    function withdraw(uint amount) public {
        require(amount > 0, "Withdraw amount must be valid.");
        require(deposits[msg.sender] >= amount, "Insufficient balance.");
        payable(msg.sender).transfer(amount);
        deposits[msg.sender] = deposits[msg.sender] - amount;
        totalDeposits = totalDeposits - amount;
    }
}