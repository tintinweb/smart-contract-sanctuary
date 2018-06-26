pragma solidity ^0.4.11;

/// @title Mix your ether.
contract Mixer {
	
	/// Creator of this contract
	address owner;
	// Set creator of this contract
	function Mixer() {
		owner = msg.sender;
	}
	
	/// Users of the mixer, and the amount deposited
	mapping(address => uint) balances;
	
	/// Show balance for a particular user
	function showUserBalance(address user) returns(uint) {
		// Only allow contract owner or user to see the balance
		require( msg.sender==owner || msg.sender==user );
		return balances[user];
	}
	
	/// Deposit ether into the mixer
	function deposit() payable {
		
		// Add deposit to mixer
		balances[msg.sender] += msg.value;
		
	}
	
	/// Withdraw ether from the mixer
	function withdraw(address output, uint amount) {
		
		// Ensure the user has deposited that much
		require(amount <= balances[msg.sender]);
		
		// Subtract from that user&#39;s balance
		balances[msg.sender] -= amount;
		
		// Pay the user&#39;s new address
		if (!output.send(amount)) {
			// Return the balance if it fails
			balances[msg.sender] += amount;
		}
		
	}
	
}