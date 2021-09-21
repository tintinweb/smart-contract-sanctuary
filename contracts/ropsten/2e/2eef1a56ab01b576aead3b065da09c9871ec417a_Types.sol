/**
 *Submitted for verification at Etherscan.io on 2021-09-21
*/

// Solidity program to
// demonstrate the use
// of 'For loop'
pragma solidity ^0.8.0;

// Creating a contract
contract Types {
	uint256 public count;
    uint256 public lastExecuted;
    uint256 amount;
	// Declaring a dynamic array
	uint[] data;

	// Defining a function
	// to demonstrate 'For loop'
	function loop(uint amount) public returns(uint[] memory){
	    require(((block.timestamp - lastExecuted) > 110), "Counter: increaseCount: Time not elapsed");
        
	for(uint i=0; i<5; i++){
		data.push(i);
	}
	count += amount;
    lastExecuted = block.timestamp;
	return data;
	
	}
	

}