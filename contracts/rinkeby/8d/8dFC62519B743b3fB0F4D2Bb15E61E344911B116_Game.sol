/**
 *Submitted for verification at Etherscan.io on 2021-08-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.5;

contract Game {
	address owner;

	mapping(address => mapping(string => bool)) public talents;
	// these points are points people can spend on talents
	// each address gets a point every time they level up
	mapping(address => uint) public points;

	constructor() {
	    owner = msg.sender;
	}

	// TODO: grant the address 1 point they can spend
	// is called by the game to level up a user
	function levelUp(address user) public {
		require(msg.sender == owner);
		points[user]++;
	}

	// TODO: grant the address the corresponding talent
	// by the user to choose their talent
	function chooseTalent(string memory cid) public {
		// if someone has zero points we should REVERT
		require(points[msg.sender] > 0);
		// 1. set the msg.sender's talent in the talents mapping
		talents[msg.sender][cid] = true;
		// 2. decrement the msg.sender's points
		points[msg.sender]--;
	}
}