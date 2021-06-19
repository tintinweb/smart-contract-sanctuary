/**
 *Submitted for verification at Etherscan.io on 2021-06-18
*/

pragma solidity ^0.4.0;

// Creating a contract
contract GeeksForGeeks
{
	// Declaring the state variable
	uint x;
	
	address public owner;
	// Mapping of addresses to their balances
	mapping(address => uint) public balance;

	// Creating a constructor
	constructor() public
	{
		// Set x to default
		// value of 10
		x=10;
        owner=msg.sender;
	}

	// Creating a function
	function SetX(uint _x) public returns(bool)
	{
		// Set x to the
		// value sent
		x=_x;
		return true;
	}
	
	// This fallback function
	// will keep all the Ether
	function() public payable
	{
		balance[msg.sender] += msg.value;
	}
}