/**
 *Submitted for verification at Etherscan.io on 2021-06-26
*/

// SPDX-License-Identifier: Unlicense
/// @author Felix Nan

/* 
Hardhat Token
website: https://hardhat.org

888    888                      888 888               888
888    888                      888 888               888
888    888                      888 888               888
8888888888  8888b.  888d888 .d88888 88888b.   8888b.  888888
888    888     "88b 888P"  d88" 888 888 "88b     "88b 888
888    888 .d888888 888    888  888 888  888 .d888888 888
888    888 888  888 888    Y88b 888 888  888 888  888 Y88b.
888    888 "Y888888 888     "Y88888 888  888 "Y888888  "Y888

*/

pragma solidity ^0.7.0;

// Hardhat Token Contract
contract Token {
	string public name = "Felix Nan Token";
	string public symbol = "FNT";

	uint256 public totalSupply = 1000000;

	address public owner;

  	mapping(address => uint256) balances;

	event Transfer(address to, uint amount);

	/**
	* Contract initialization.
	*
	* Is executed only once when the contract is created.
	* Assign totalSupply to the transaction sender - the account that is deploying the contract.
	*/
	constructor() {
		balances[msg.sender] = totalSupply;
		owner = msg.sender;
	}

	/**
	* A function to transfer tokens.
	*
	* `external` only callable from outside the contract.
	*/
	function transfer(address to, uint256 amount) external {
		/// @notice check if the transaction sender has enough tokens. If not transaction will revert.
		require(balances[msg.sender] >= amount, "You don't have enough tokens.");

		balances[msg.sender] -= amount;
		balances[to] += amount;
		emit Transfer(to, amount);
	}

	/**
	* A function to retrieve the token balance of the account
	*
	* `view` doesn't modify the contract's state. Allows us to call without executing a transaction.
	*/
	function balanceOf(address account) external view returns (uint256) {
		return balances[account];
	}
}