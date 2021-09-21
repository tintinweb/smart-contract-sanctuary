/**
 *Submitted for verification at Etherscan.io on 2021-09-21
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.7;

contract Inbox {
	string public message;

	constructor(string memory initialMessage) {
		message = initialMessage;
	}

	function setMessage(string memory newMessage) public {
		message = newMessage;
	}

	// Public variable will automatically create a get function as the name of the variable
	// So actually we do not need getMessage() function.
	function getMessage() public view returns (string memory) {
		return message;
	}
}