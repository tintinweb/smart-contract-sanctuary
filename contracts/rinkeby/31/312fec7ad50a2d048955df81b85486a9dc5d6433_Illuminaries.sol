// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;

import './ERC721Enumerable.sol';
import './Ownable.sol';
import './Strings.sol';
import './Payment.sol';
import './Guard.sol';

contract Illuminaries is ERC721Enumerable, Ownable, Payment, Guard {
    using Strings for uint256;
    string public baseURI;

  	//settings
  	uint256 public maxSupply = 100;

	//shares
	address[] private addressList = [
		0x0Aa1F3d61e7c325aE795737266c5FD6839819b86];
	uint[] private shareList = [100];

	//token
	constructor(
	string memory _name,
	string memory _symbol,
	string memory _initBaseURI
	) 
    ERC721(_name, _symbol)
	    Payment(addressList, shareList){
	    setURI(_initBaseURI);
	}

	// admin minting directly to receipent
	function giftHonorary(uint256 tokenId, address recipient) external onlyOwner{
		require(tokenId <= maxSupply);
		_safeMint( recipient, tokenId);
	}

	//read metadata
	function _baseURI() internal view virtual returns (string memory) {
		return baseURI;
	}

	function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
		require(tokenId <= maxSupply);
		string memory currentBaseURI = _baseURI();
		return bytes(currentBaseURI).length > 0	? string(abi.encodePacked(currentBaseURI, tokenId.toString())) : "";
	}

	//write metadata
	function setURI(string memory _newBaseURI) public onlyOwner {
		baseURI = _newBaseURI;
	}
	
	//supply switch if the ancients deem necessary
	function setMax(uint256 _newMaxSupply) public onlyOwner {
		maxSupply = _newMaxSupply;
	}

	//withdraw
	function withdraw() public payable onlyOwner {
		(bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
		require(success);
	}
}