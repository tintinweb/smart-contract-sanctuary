pragma solidity 0.8.10;

import "./ERC721.sol";

contract SuperMarioWorld is ERC721 {
	string public name;
	string public symbol;
	uint256 public tokenCount;

	mapping(uint256 => string) private _tokenURIs;

	constructor(string memory _name, string memory _symbol) {
		name = _name;
		symbol = _symbol;
		tokenCount = 0;
	}

	function tokenURI(uint256 tokenId) public view returns (string memory) {
		require(_owners[tokenId] != address(0), "TokenID does not exist");
		return _tokenURIs[tokenId];
	}

	function mint(string memory _tokenURI) public {
		tokenCount += 1;
		_balances[msg.sender] += 1;
		_owners[tokenCount] = msg.sender;
		_tokenURIs[tokenCount] = _tokenURI;

		emit Transfer(address(0), msg.sender, tokenCount);
	}

	function supportsInterface(bytes4 interfaceId)
		public
		pure
		override
		returns (bool)
	{
		return interfaceId == 0x80ac58cd || interfaceId == 0x5b5e139f;
	}
}