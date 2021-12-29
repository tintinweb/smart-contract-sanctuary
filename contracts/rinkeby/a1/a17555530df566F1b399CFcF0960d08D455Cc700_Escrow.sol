/**
 *Submitted for verification at Etherscan.io on 2021-12-29
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

contract Escrow {
	address public arbiter;
	address payable public beneficiary;
	address payable public depositor;

	bool public isApproved;

	constructor(address _arbiter, address payable _beneficiary) payable {
		arbiter = _arbiter;
		beneficiary = _beneficiary;
		depositor = msg.sender;
	}

	event Approved(uint);
	event Cancelled(uint);

	function approve() external {
		// security: only the arbiter can approve
		require(msg.sender == arbiter);
		uint balance = address(this).balance;
		beneficiary.transfer(balance);
		emit Approved(balance);
		isApproved = true;
	}

	function cancel() external {
		// security: only the arbiter can cancel the contract
		require(msg.sender == arbiter);
		// cancel the contract and return funds to the depositor
		emit Cancelled(address(this).balance);	// emit event to notify the beneficiary if necessary
		selfdestruct(depositor);
	}
}