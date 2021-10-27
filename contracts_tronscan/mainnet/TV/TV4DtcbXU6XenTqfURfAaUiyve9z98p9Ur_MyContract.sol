//SourceUnit: mytest.sol

// Solidity program to
// retrieve address and
// balance of owner
pragma solidity ^0.5.10;	

// Creating a contract
contract MyContract
{
	// Private state variable
	address private owner;

	// Defining a constructor
	constructor() public{
		owner=msg.sender;
	}

	// Function to get
	// address of owner
	function getOwner(
	) public view returns (address) {	
		return owner;
	}

	// Function to return
	// current balance of owner
	function getBalance(
	) public view returns(uint256){
		return owner.balance;
	}
}