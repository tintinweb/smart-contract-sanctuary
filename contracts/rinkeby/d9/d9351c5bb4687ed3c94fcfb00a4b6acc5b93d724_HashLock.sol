/**
 *Submitted for verification at Etherscan.io on 2021-08-12
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;
	contract HashLock {
	    bytes32 public constant hashLock = bytes32(0xE77EFFB78FB9ED9748847D33EE9B703C2AFFEF3F4F3EBE7C67AAF194710D3E9D);
	    receive() external payable {}
	    function claim(string memory _WhatIsTheMagicKey) public {
	        require(sha256(abi.encodePacked(_WhatIsTheMagicKey)) == hashLock);
	        selfdestruct(msg.sender);
	    }
	}