// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./Ownable.sol";

contract BFKCRO is ERC20, Ownable {
	constructor() ERC20("BFKCRO", "BFKCRO") {
		_mint(msg.sender, 1000000000 * 10**decimals());
	}

	function mint(address to, uint256 amount) public onlyOwner {
		_mint(to, amount);
	}
}