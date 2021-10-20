// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract JCorp_collectors is ERC721Enumerable, Ownable {
	using Strings for uint256;
	
	event BaseURIChanged(string newBaseURI);
	
	string public baseURI;	
	
    constructor(
		string memory _name,
		string memory _symbol
    ) ERC721(_name, _symbol) {}
	
	function giftTokens(address[] calldata _to) external onlyOwner {
		uint256 supply = totalSupply();
		
		for(uint256 i = 0; i < _to.length; i++) {
			supply += 1;
			_safeMint(_to[i], supply);
		}
	}
	
	function setBaseURI(string calldata _newBaseURI) external onlyOwner {
		baseURI = _newBaseURI;
		emit BaseURIChanged(_newBaseURI);
    }
	
	function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
}