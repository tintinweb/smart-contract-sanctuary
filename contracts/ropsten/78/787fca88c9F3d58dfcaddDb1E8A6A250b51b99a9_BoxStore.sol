// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BoxStore {
	address private _owner;

	mapping(address => bool) public tracker;

	constructor() {
		_owner = msg.sender;
		tracker[msg.sender] = true;
	}
}