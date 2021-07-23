/**
 *Submitted for verification at Etherscan.io on 2021-07-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.5.16;

contract OenPiece {
	string  name;
	uint  age;
	function setProfile(uint _age,string calldata _name) external returns (bool){
		name = _name;
		age = _age;
		return true;
	}
	function getName() view public returns(string memory){
		return name;
	}
}