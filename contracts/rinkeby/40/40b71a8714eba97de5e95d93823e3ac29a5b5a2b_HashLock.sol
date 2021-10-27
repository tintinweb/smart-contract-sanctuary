/**
 *Submitted for verification at Etherscan.io on 2021-10-27
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0; //different version has different intepretation
	contract HashLock { //one contract
	    bytes32 public constant hashLock = bytes32(0xEE5CAEFFD6AC4C11C9E9A9F21EAD9CE81987A42F2912CB2EDCFA11ED1503CDBB); //32 byte data, public open, lock is a 32 bype hash (head of lock)
	    receive() external payable {} //can receive money after adding from others, deposit hole
	    function claim(string memory _WhatIsTheMagicKey) public { 
	        require(sha256(abi.encodePacked(_WhatIsTheMagicKey)) == hashLock); //if this condition is okay, proceed
	        selfdestruct(msg.sender); //self-destroy, all asset will be sent to the caller of the send function
	    }
	}