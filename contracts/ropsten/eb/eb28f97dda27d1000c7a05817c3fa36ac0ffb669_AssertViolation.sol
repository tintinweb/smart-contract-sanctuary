/**
 *Submitted for verification at Etherscan.io on 2021-11-02
*/

// SPDX-License-Identifier: GPL-3.0

/*
    === TxT Test Case for SWC-110 ===

    STATUS: [complete]
    DEPLOYED AT: 0xeB28F97Dda27D1000C7a05817c3fa36aC0FfB669

    VULNERABILITY REPRODUCTION STEPS:
    1. Call deposit() with a value that doesn't correspond to the amount
    
    EXPECTED OUTCOME:
    Since Assert should not be reached in normal execution, it should
    not be used to validate input since gas is not returned.
    
    ACTUAL OUTCOME:
    Assert is used to validate input and gas is not returned after failure.
    
    NOTES:
    None
*/

pragma solidity >=0.7.0 <0.9.0;

contract AssertViolation {
	mapping(address => uint256) public balanceOf;
	
	function deposit(uint256 amount) public payable {
	    assert(msg.value == amount);
	    balanceOf[msg.sender] = msg.value;
	}
}