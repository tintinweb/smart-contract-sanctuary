/**
 *Submitted for verification at Etherscan.io on 2021-11-02
*/

// SPDX-License-Identifier: GPL-3.0

/*
    === TxT Test Case for SWC-135 ===

    STATUS: [complete]
    DEPLOYED AT: 0x5fD034649b757da1F790C375B67764219a6C9e43

    VULNERABILITY REPRODUCTION STEPS:
    1. Call deposit() with some ether
    2. Call withdraw()
    
    EXPECTED OUTCOME:
    The amount you deposited is withdrawn.
    
    ACTUAL OUTCOME:
    The contract holds your funds because the deposit function 
    did not store any amount anywhere indicating how much ether is yours.
    
    NOTES:
    None
*/

pragma solidity >=0.7.0 <0.9.0;

contract DepositBox {
    mapping(address => uint) balance;

    // Accept deposit
    function deposit() public payable {
        // Should update user balance
        balance[msg.sender] == msg.value;
    }
    
    function withdraw() public {
        payable(msg.sender).transfer(balance[msg.sender]);
    }
}