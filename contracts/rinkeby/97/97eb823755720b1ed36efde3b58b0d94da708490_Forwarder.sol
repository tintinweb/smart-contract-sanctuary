//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./ERC20Interface.sol";

/**
 * Contract that will forward any incoming Ether to its creator
 */
contract Forwarder {
	using SafeMath for uint256;

	address payable payoutAddress;
	// Admin addresses
	mapping (address => bool) admins;

	// Create the contract, and set the payout address to that of the creator
	constructor() {
		admins[msg.sender] = true;
		payoutAddress = payable(msg.sender);
	}

	//Default function; blocks payments not sent via the pay() function
	receive() external payable {
		revert("This contract can only receive funds via the pay() function");
	}
	
	//ETH payments
	function pay(bytes8 invoice_id, address pay_to, uint256 total) public payable {
		require (
			msg.value > 0,
			"Invoice value must be more than 0!"
		);
		require (
			invoice_id != hex"0000000000000000",
			"Invalid invoice ID"
		);		
		require (
			total > 0,
			"Invoice total must be more than 0!"
		);
		require (
			msg.value >= total,
			"Your payment is less than the invoice total!"
		);
		payable(pay_to).transfer(msg.value);
	}
	
	//ERC20 payments
	function payToken(bytes8 invoice_id, address tokenContractAddress, address pay_to, uint256 total) public {
		require (
			invoice_id != hex"0000000000000000",
			"Invalid invoice ID"
		);		
		require (
			total > 0,
			"Invoice total must be more than 0!"
		);
		require (
			tokenContractAddress != address(0),
			"Invalid token contract!"
		);
		
		ERC20Interface instance = ERC20Interface(tokenContractAddress);
		uint256 bal = instance.balanceOf(msg.sender);
		require (
			bal >= total,
			"You do not have enough of that token to pay the total!"
		);
		
		uint256 allowed = instance.allowance(msg.sender, address(this));
		require (
			allowed >= total,
			"You have not allowed us to spend enough token to pay the total!"
		);
		
		if (!instance.transferFrom(msg.sender, pay_to, total)) {
			revert();
		}
	}

	modifier onlyAdmin() { // Modifier
		require(
			admins[msg.sender] == true,
			"Only admins can call this."
		);
		_;
	}

	//In case any ETH builds up, sweep the balance to the payout address.
	function sweep() public onlyAdmin {
		require(address(this).balance > 0);
		payoutAddress.transfer(address(this).balance);
	}
	

	//In case any ERC20 tokens build up, sweep the balance to the payout address.
	function sweepToken(address tokenContractAddress) public onlyAdmin {
		require(tokenContractAddress != address(0));
		ERC20Interface instance = ERC20Interface(tokenContractAddress);
		uint256 bal = instance.balanceOf(address(this));
		require (bal > 0);
		if (!instance.transfer(payoutAddress, bal)) {
			revert();
		}
	}	

	//Gives or removes authority to other addresses to sweep funds	or change the payout address
	function setAdministrator(address addr, bool status) public onlyAdmin {
		require(addr != address(0));
		admins[addr] = status;
	}  

	function setPayoutAddress(address payable newAddr) public onlyAdmin {
		require(newAddr != address(0));
		payoutAddress = newAddr;
	}

	//If you ever want to stop accepting payments, can call this to destroy the contract.
	//Important: If there are any ERC20 tokens in the balance and you call this they are lost forever.
	function goodbye() public onlyAdmin {
		selfdestruct(payoutAddress);
	}
}