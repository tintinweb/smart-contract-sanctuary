// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.3.2 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.7;

import "./ERC20.sol";
import "./ERC20Burnable.sol";

contract ReleaseToken is ERC20, ERC20Burnable {
	constructor(string memory name_, string memory symbol_, uint256 totalSupply_) ERC20(name_, symbol_) {
		_mint(msg.sender, (10**decimals())*totalSupply_);
	}
}