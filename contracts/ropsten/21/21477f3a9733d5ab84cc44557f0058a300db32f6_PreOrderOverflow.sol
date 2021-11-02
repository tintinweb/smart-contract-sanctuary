/**
 *Submitted for verification at Etherscan.io on 2021-11-02
*/

// SPDX-License-Identifier: GPL-3.0

/*
    === TxT Test Case for SWC-101 (Overflow) ===

    STATUS: [complete]
    DEPLOYED AT: 0x21477f3a9733d5ab84cc44557f0058a300db32f6

    VULNERABILITY REPRODUCTION STEPS:
    1. Call the Deposit Function with Some Ethereum as the Value
    2. Call the withdrawAll function to make the allowedTransactions counter for the sender Overflow
    3. Call the withdrawAll function again. Despite the user exceeding the maximum transaction count, they
       are still able to make transactions due to an overflow.
    
    EXPECTED OUTCOME:
    On the second withdrawAll call, the EVM will revert the transaction due to the transaction counter
    being over the limit.
    
    ACTUAL OUTCOME:
    The allowedTransactions counter for the address is overflowed, leading to a situation where the 255th transaction
    leads to an overflow, leading to a situation where any user can make any number of transactions.
    
    NOTES:
    None
*/

pragma solidity ^0.4.22;

contract PreOrderOverflow {
    mapping(address => uint256) public balanceOf;
    uint8 public allowedTransactions;
    

    
    function deposit() public payable {
        balanceOf[msg.sender] = msg.value;
    }
    
    function withdrawAll() public {
        require(allowedTransactions < 256);
        msg.sender.transfer(balanceOf[msg.sender]);
        allowedTransactions = allowedTransactions + 1;
    }
    
    constructor() public {
        allowedTransactions = 255;
    }
}