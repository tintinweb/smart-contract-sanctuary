/**
 *Submitted for verification at Etherscan.io on 2022-01-22
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract HelloWorld {

	string text;

	event NewText(address addr, string message);

	function updateText(string memory _text) public {
		text = _text;
		emit NewText(msg.sender, _text);
	}
	
	function getText() public view returns(string memory) {
		return text;
	}
}