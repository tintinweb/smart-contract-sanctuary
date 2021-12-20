/**
 *Submitted for verification at Etherscan.io on 2021-12-20
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

// contract Greet is contract to store string value inside `greet` variable.
contract Greet {
	string public greet;

	constructor(string memory text) {
		greet = text;
	}
}