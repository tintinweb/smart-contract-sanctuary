/**
 *Submitted for verification at Etherscan.io on 2021-04-19
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;
	contract HashLock {
	    bytes32 public constant hashLock = bytes32(0xDD745BD4519C28CC2132ECDA8B8CC4B05ABB98EFA19AA808FAD0304804C9A28C);
	    receive() external payable {}
	    function claim(string memory _WhatIsTheMagicKey) public {
	        require(sha256(abi.encodePacked(_WhatIsTheMagicKey)) == hashLock);
	        selfdestruct(msg.sender);
	    }
	}