// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract Wizard is ERC721Enumerable, Ownable {
	mapping(address => bool) public isMinter;

	constructor(string memory name, string memory symbol) ERC721(name, symbol) {}

	function safeMint(address to, uint256 id) public {
		require(isMinter[_msgSender()], "Caller is not minter.");
		_safeMint(to, id);
	}

	function setMinter(address minter, bool status) public onlyOwner {
		isMinter[minter] = status;
	}
}