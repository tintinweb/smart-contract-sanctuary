/**
 *Submitted for verification at Etherscan.io on 2021-08-23
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.4;

contract BancoDeBernard {
    mapping(address => uint) public deposits;
    uint public totalDeposits = 0;
    
    mapping(address => uint) public withdrawals;
    uint public totalWithdrawals = 0;
    
    function deposit() public payable {
        deposits[msg.sender] = deposits[msg.sender] + msg.value;
        totalDeposits = totalDeposits + msg.value;
    }
    
    function withdraw(uint amount) public {
        require(deposits[msg.sender] >= amount, "Insufficient Balance");
        withdrawals[msg.sender] = withdrawals[msg.sender] + amount;
        
        totalWithdrawals = totalWithdrawals + amount;
        
        payable(msg.sender).transfer(amount);
    }
    
}