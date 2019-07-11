/**
 *Submitted for verification at Etherscan.io on 2019-07-05
*/

pragma solidity >=0.4.0 <0.6.0;

contract Faucet {
	// event definition
	event Withdrawal(address indexed to, uint amount);
	event Deposit(address indexed from, uint amount);

	// Give out ether to anyone who asks
	function withdraw(uint withdraw_amount) public {

		// Limit withdrawal amount   
		// note the keyword require instead of using if  why? 
		// if condition not met immiditely returns comusing just this much execution cost -fee
		require(withdraw_amount <= 0.1 ether, "withdraw amount is too large");
		require(address(this).balance >= withdraw_amount,
			"Insufficient balance in faucet for withdrawal request");
		// Send the amount to the address that requested it
		msg.sender.transfer(withdraw_amount);

		// firing events 
		emit Withdrawal(msg.sender, withdraw_amount);
	}
	// Accept any incoming amount
	function () external payable {
		emit Deposit(msg.sender, msg.value);
	}
}