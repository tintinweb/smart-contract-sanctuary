// SPDX-License-Identifier: MIT
pragma solidity ^0.7.5;

contract Game {
	address owner;

	mapping(address => mapping(string => bool)) public talents;
	mapping(address => uint) public points;

	constructor() {
	    owner = msg.sender;
	}

	function levelUp(address user) public {
	    require(msg.sender == owner);
	    points[user]++;
	}

	function chooseTalent(string memory cid) public {
	    require(points[msg.sender] > 0);
	    talents[msg.sender][cid] = true;
	    points[msg.sender]--;
	}
}