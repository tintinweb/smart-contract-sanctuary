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
	// admin minting
	function giftHonorary(uint[] calldata gifts, address[] calldata recipient) external onlyOwner{
	require(gifts.length == recipient.length);
	uint g = 0;
	uint256 s = totalSupply();
	for(uint i = 0; i < gifts.length; ++i){
	g += gifts[i];
	}
	require( s + g <= maxSupply, "Too many" );
	delete g;
	for(uint i = 0; i < recipient.length; ++i){
	for(uint j = 0; j < gifts[i]; ++j){
	_safeMint( recipient[i], s++, "" );
	}
	}
	delete s;	
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