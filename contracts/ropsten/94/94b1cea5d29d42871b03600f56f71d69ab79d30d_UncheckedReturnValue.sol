/**
 *Submitted for verification at Etherscan.io on 2021-11-02
*/

// SPDX-License-Identifier: GPL-3.0

/*
    === TxT Test Case for SWC-104 ===

    STATUS: [complete]
    DEPLOYED AT: 0x...

    VULNERABILITY REPRODUCTION STEPS:
    1. Use the deposit function to put money in the contract
    2. Call the sendMoney function to receive ether
    
    EXPECTED OUTCOME:
    The call to callee in sendMoney will fail and the ether will stay in the contract
    
    ACTUAL OUTCOME:
    Since the call to the function in callee is not checked, our contract doesn't care
    that it failed, and sends money anyway. The balance of the sender increases as a result.
    
    NOTES:
    None
*/

pragma solidity >=0.7.0 <0.9.0;

contract UncheckedReturnValue {
    // Random Address that probably doesn't have a smart contract associated with it
	address callee = address(0x5B38Da6a701c568545dCfcB03FcB875f56beddC4);
	mapping(address => uint256) amount;
	
	function sendMoney() public {
	    callee.call("");
	    payable(msg.sender).transfer(amount[msg.sender]);
	}
	
	function deposit() public payable {
	    amount[msg.sender] = msg.value;
	}
}