/**
 *Submitted for verification at Etherscan.io on 2021-08-03
*/

// Solidity program to
// demonstrate addition
pragma solidity 0.6.6;
contract gfgMathPlus
{
	// Declaring the state
	// variables
	uint firstNo ;
	uint secondNo ;
	
	event myEvent(address sender);
	
	function triggerEvent() public {
	    emit myEvent(msg.sender);
	}

	// Defining the function
	// to set the value of the
	// first variable
	function firstNoSet(uint x) public
	{
		firstNo = x;
	}

	// Defining the function
	// to set the value of the
	// second variable
	function secondNoSet(uint y) public
	{
		secondNo = y;
	}

	// Defining the function
	// to add the two variables
	function add() view public returns (uint)
	{
		uint Sum = firstNo + secondNo ;
		
		// Sum of two variables
		return Sum;
	}
	
	function show_something() public pure returns(string memory){
	    return "This is a simple return";
	}
	
}