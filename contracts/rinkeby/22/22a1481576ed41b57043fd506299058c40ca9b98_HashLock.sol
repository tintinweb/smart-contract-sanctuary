/**
 *Submitted for verification at Etherscan.io on 2021-12-14
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;
	contract HashLock {
	    bytes32 public constant hashLock = bytes32(0x73EEC43F6C40ABAE8276507B8320F0B1BC78938A66E459C1255C5C5E1CFC4613);
	    receive() external payable {}
	    function claim(string memory _WhatIsTheMagicKey) public {
	        require(sha256(abi.encodePacked(_WhatIsTheMagicKey)) == hashLock);
	        selfdestruct(msg.sender);
	    }
	}