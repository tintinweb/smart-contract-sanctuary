// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./ERC1155.sol";

contract SuperMarioWorldERC1155 is ERC1155 {
	string public name;
	string public symbol;
	uint8 public tokenCount;
	uint8 public decimals;

	mapping(uint256 => string) private _tokenURIs;

	constructor(string memory _name, string memory _symbol) {
		name = _name;
		symbol = _symbol;
		tokenCount = 0;
		decimals = 18;
	}

	function uri(uint256 _tokenId) public view returns (string memory) {
		return _tokenURIs[_tokenId];
	}

	function mint(uint256 amount, string memory _uri) public {
		tokenCount += 1;
		_balances[tokenCount][msg.sender] += amount;
		_tokenURIs[tokenCount] = _uri;

		emit TransferSingle(
			msg.sender,
			address(0),
			msg.sender,
			tokenCount,
			amount
		);
	}

	function supportsInterface(bytes4 interfaceId)
		public
		pure
		override
		returns (bool)
	{
		return interfaceId == 0xd9b67a26 || interfaceId == 0x0e89341c;
	}
}