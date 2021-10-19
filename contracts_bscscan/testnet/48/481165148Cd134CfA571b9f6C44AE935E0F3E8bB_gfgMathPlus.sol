/**
 *Submitted for verification at BscScan.com on 2021-10-18
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
}