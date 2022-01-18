/**
 *Submitted for verification at Etherscan.io on 2022-01-18
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//import "hardhat/console.sol";

contract WavePortal {

	uint256 totalWaves;
	mapping(address => bool) addressWaved;
	address _owner;

	constructor() {
		_owner = msg.sender;
		//console.log("contract initialized...");
		//console.log("has owner waved: ", addressWaved[msg.sender]);
	}

	function wave() public {
		totalWaves += 1;
		addressWaved[msg.sender] = true;
		//console.log("someone waved: %s", msg.sender);
	}

	function getTotalWaves() public view returns(uint) {
		//console.log("total waves: %s", totalWaves);
		return totalWaves;
	}

	function getWaivers(address _address) public view returns(bool) {
		//console.log("is %s waved: ", _address, addressWaved[_address]);
		return addressWaved[_address];
	}
}