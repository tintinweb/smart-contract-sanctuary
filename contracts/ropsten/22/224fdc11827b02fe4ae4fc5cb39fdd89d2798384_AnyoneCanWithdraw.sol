/**
 *Submitted for verification at Etherscan.io on 2021-11-02
*/

// SPDX-License-Identifier: GPL-3.0

/*
    === TxT Test Case for SWC-105 ===

    STATUS: [complete]
    DEPLOYED AT: 0x224FDc11827b02fE4AE4FC5cB39fDd89D2798384

    VULNERABILITY REPRODUCTION STEPS:
    1. Call deposit() to load the contract with ether
    2. Call withdraw() with any wallet to withdraw funds.
    
    EXPECTED OUTCOME:
    Withdraw will be private and not callable due the fact that no access
    specifier is defined.
    
    ACTUAL OUTCOME:
    Anybody can call withdraw because no access specifier defaults to public
    in older versions of solidity.
    
    NOTES:
    None
*/

pragma solidity ^0.4.21;

contract AnyoneCanWithdraw {
	mapping(address => uint256) public balanceOf;
	
	function deposit() public payable{
	    balanceOf[msg.sender] += msg.value;
	}
	
	function withdraw() {
	    uint256 balance = balanceOf[msg.sender];
	    msg.sender.transfer(balance);
	}
}