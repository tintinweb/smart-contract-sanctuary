/**
 *Submitted for verification at Etherscan.io on 2021-07-19
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0; 

	contract HashLock {
	    
	    bytes32 public constant hashLock = bytes32(0xB59439358A9488ABCB0292C8A10A971424FD245A906DD355494AB87898CB26AD);
	    receive() external payable {}
	    function claim(string memory _WhatIsTheMagicKey) public {
	        require(sha256(abi.encodePacked(_WhatIsTheMagicKey)) == hashLock);
	        selfdestruct(msg.sender);
	    }
	    
	}