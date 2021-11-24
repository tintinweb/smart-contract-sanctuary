// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import './ERC721Enumerable.sol';
import './Ownable.sol';
import './Strings.sol';
import './Payment.sol';
import './Guard.sol';

contract Main is ERC721Enumerable, Ownable, Payment, Guard {
  using Strings for uint256;
  string public baseURI;

  //settings
  uint256 public maxSupply = 500;
  uint256 public maxMint = 2;
  uint256 private price = 0.01 ether;
  bool public contractStatus = false;
	mapping(address => uint256) public onWhitelist;

	address[] private addressList = [
	0x2349334b6c1Ee1eaF11CBFaD871570ccdF28440e,
	0x692D7e00ea2F78527a4aBa96694E9Eb63AeDA1Eb,
  0xcfd9e3204Ab9A1CC097B71f1e0b27E3929bB8e1b
	];
	uint[] private shareList = [30,30,40];
  
	constructor(
	string memory _name,
	string memory _symbol,
	string memory _initBaseURI
	) 
    ERC721(_name, _symbol)
	    Payment(addressList, shareList){
	    setURI(_initBaseURI);
	}

// public minting
	function mint(uint256 _tokenAmount) public payable nonReentrant{
	uint256 currentSupply = totalSupply();
	require(contractStatus, "Contract is not active" );
	require(_tokenAmount > 0, "Mint more than 0" );
	require(_tokenAmount <= maxMint, "Mint less");
	require(currentSupply + _tokenAmount <= maxSupply, "Mint less");
	require(msg.value >= price * _tokenAmount, "ETH input is wrong");
	for (uint256 i = 0; i < _tokenAmount; ++i) {
	_safeMint(msg.sender, currentSupply + i, "");
	}
	delete currentSupply;
	}

// whitelist minting
	function mintWhitelist(uint256 _tokenAmount) public payable {
	uint256 currentSupply = totalSupply();
  uint256 whitelistAmount = onWhitelist[msg.sender];
	require(contractStatus, "Contract is not active" );
	require(_tokenAmount > 0, "Mint more than 0" );
	require(_tokenAmount <= maxMint, "Mint less");
	require(currentSupply + _tokenAmount <= maxSupply, "Mint less");
	require(msg.value >= price * _tokenAmount, "ETH input is wrong");
  onWhitelist[msg.sender] = whitelistAmount - _tokenAmount;
  delete whitelistAmount;
	for (uint256 i = 0; i < _tokenAmount; ++i) {
	_safeMint(msg.sender, currentSupply + i, "");
	}
	delete currentSupply;
	}
  
   // admin functionality
	function whitelistSet(address[] calldata _addresses, uint256[] calldata _amounts) public onlyOwner {
	for(uint256 i; i < _addresses.length; i++){
	onWhitelist[_addresses[i]] = _amounts[i];
	}
	}

	function _baseURI() internal view virtual returns (string memory) {
	return baseURI;
	}

	function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
	require(_exists(tokenId), "Nonexistent token");
	string memory currentBaseURI = _baseURI();
	return bytes(currentBaseURI).length > 0	? string(abi.encodePacked(currentBaseURI, tokenId.toString())) : "";
	}

	function setPrice(uint256 _newPrice) public onlyOwner {
	price = _newPrice;
	}

	function setMaxMint(uint256 _newMaxMintAmount) public onlyOwner {
	maxMint = _newMaxMintAmount;
	}

	function setSupply(uint256 _newMaxSupply) public onlyOwner {
	maxSupply = _newMaxSupply;
	}

	function setURI(string memory _newBaseURI) public onlyOwner {
	baseURI = _newBaseURI;
	}

	function setStatus(bool _status) public onlyOwner {
	contractStatus = _status;
	}

	function withdraw() public payable onlyOwner {
	(bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
	require(success);
	}
}