// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import './ERC721.sol';
import './ERC721Enumerable.sol';

contract UndeadDoodle is ERC721, ERC721Enumerable {
	uint256 constant FREE_SUPPLY = 1000;
	uint256 constant MAX_SUPPLY = 4000;

	address immutable owner;

	uint256 id = 0;

	constructor() ERC721('Undead Doodles', 'UDD') {
		owner = msg.sender;
	}

	function _baseURI() internal pure override returns (string memory) {
		return 'https://undeaddoodles.com/tokens/';
	}

	function mint(uint256 _amount) external payable {
		require(_amount > 0 && _amount < 20, 'Amount must be between 0 and 20 tokens.');
		require(id < MAX_SUPPLY, 'All tokens have been minted.');
		require(id < FREE_SUPPLY || msg.value > 0, 'All free tokens have been minted.');

		payable(owner).transfer(msg.value);

		for (uint256 i = 0; i < _amount; i++) {
			_safeMint(msg.sender, id);
			id++;
		}
	}

	// The following overrides required.

	function _beforeTokenTransfer(
		address from,
		address to,
		uint256 tokenId
	) internal override(ERC721, ERC721Enumerable) {
		super._beforeTokenTransfer(from, to, tokenId);
	}

	function supportsInterface(bytes4 interfaceId)
		public
		view
		override(ERC721, ERC721Enumerable)
		returns (bool)
	{
		return super.supportsInterface(interfaceId);
	}
}