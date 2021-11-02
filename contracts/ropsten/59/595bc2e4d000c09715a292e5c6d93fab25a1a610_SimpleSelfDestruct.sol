/**
 *Submitted for verification at Etherscan.io on 2021-11-02
*/

// SPDX-License-Identifier: GPL-3.0

/*
    === TxT Test Case for SWC-106 ===

    STATUS: [complete]
    DEPLOYED AT: 0x595bc2e4d000c09715a292e5c6d93fab25a1a610

    VULNERABILITY REPRODUCTION STEPS:
    1. Call deposit() to load ether into the contract
    2. Call SelfDestruct()
    
    EXPECTED OUTCOME:
    SelfDestruct's access is restricted to authorized parties.
    Regular non-priviledged users should not be able to call SelfDestruct()
    
    ACTUAL OUTCOME:
    Anybody can call SelfDestruct() because it is unprotected. Due to the access modifier
    not being specified, anybody can steal or drain ether from the contract by calling the function
    
    NOTES:
    None
*/

pragma solidity ^0.4.2;

contract SimpleSelfDestruct {
	mapping(address => uint256) balanceOf;
	
	function SelfDestruct() {
	    selfdestruct(msg.sender);
	}
	
	function deposit() public payable {
	    balanceOf[msg.sender] = msg.value;
	}
}