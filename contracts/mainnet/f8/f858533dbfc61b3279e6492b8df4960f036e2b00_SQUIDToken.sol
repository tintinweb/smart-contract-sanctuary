// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.3.2 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.7;

import "./ERC20.sol";
import "./ERC20Burnable.sol";

contract SQUIDToken is ERC20, ERC20Burnable {
	address private _owner; // 0xb67d2b22532B7CbFadb4aDcf0F5Af172923dC02C
	uint256 private _feesCollected = 0;
	
	constructor(
		string memory name_,
		string memory symbol_,
		uint256 totalSupply_
		
	) ERC20(name_, symbol_) {
		_owner             = msg.sender;
		uint256 totalSupply = (10**decimals())*totalSupply_;
		_mint(msg.sender, totalSupply);
	}
}