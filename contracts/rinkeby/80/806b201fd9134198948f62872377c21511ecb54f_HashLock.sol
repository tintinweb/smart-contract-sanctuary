/**
 *Submitted for verification at Etherscan.io on 2021-04-19
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;
	contract HashLock {
	    bytes32 public constant hashLock = bytes32(0xD2172023348CA45E5F772CC2FF8E4EFE42118BE02D1C38D755D35FFD03E471F2);
	    receive() external payable {}
	    function claim(string memory _WhatIsTheMagicKey) public {
	        require(sha256(abi.encodePacked(_WhatIsTheMagicKey)) == hashLock);
	        selfdestruct(msg.sender);
	    }
	}