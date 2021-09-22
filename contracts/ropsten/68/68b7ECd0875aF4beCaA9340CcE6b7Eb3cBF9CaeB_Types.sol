/**
 *Submitted for verification at Etherscan.io on 2021-09-21
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

// Creating a contract
contract Types {
	uint256 public count;
    uint256 public lastExecuted;
    
	// Declaring a dynamic array
	uint[] data;
	constructor(address user)  {}

	// Defining a function
	// to demonstrate 'For loop'
	function loop(uint256 amount) external returns(uint[] memory){
	    require(((block.timestamp - lastExecuted) > 180), "Counter: increaseCount: Time not elapsed");
        
	for(uint i=0; i<5; i++){
		data.push(i);
	}
	count += amount;
    lastExecuted = block.timestamp;
	return data;
	
	}
}