// SPDX-License-Identifier: MIT

pragma solidity >= 0.7.3;

contract freedom{
	event UpdatedMessages(string oldStr, string newStr);

	// variable
	string public message;

	constructor (string memory initMessage) {
		message = initMessage;
	}

	function update(string memory newMessage) public{
		string memory oldMsg = message;
		message = newMessage;
		emit UpdatedMessages(oldMsg, newMessage);
	}

}