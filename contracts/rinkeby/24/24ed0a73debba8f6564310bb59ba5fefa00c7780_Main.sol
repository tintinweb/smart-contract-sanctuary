// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;

import './ERC721Enumerable.sol';
import './Ownable.sol';
import './Strings.sol';
import './Payment.sol';
import './Guard.sol';

contract Main is ERC721Enumerable, Ownable, Payment, Guard {
    using Strings for uint256;
    string public baseURI;

  	//settings
  	uint256 public maxSupply = 10000;
  	uint256 private price = 0.08 ether;
	uint256 public maxPerMint = 2;
	uint256 public maxPerWallet = 10;
  	bool public contractStatus = false;
	bool public whitelistStatus = false;
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
	function mint(uint256 _tokenAmount) public payable noRentry{
	uint256 s = totalSupply();
	require(contractStatus, "Contract is not active" );
	require(_tokenAmount > 0, "Mint more than 0" );
	require(_tokenAmount <= maxPerMint, "Mint less");
	require(s + _tokenAmount <= maxSupply, "Mint less");
	require(balanceOf(msg.sender) < maxPerWallet, "Mint less per wallet");
	require(msg.value >= price * _tokenAmount, "ETH input is wrong");
	for (uint256 i = 0; i < _tokenAmount; ++i) {
	_safeMint(msg.sender, s + i, "");
	}
	delete s;
	}

	// whitelist minting
	function mintWhitelist(uint256 _tokenAmount) public payable {
	uint256 s = totalSupply();
  	uint256 wl = onWhitelist[msg.sender];
	require(whitelistStatus, "Contract is not active" );
	require(_tokenAmount > 0, "Mint more than 0" );
	require(_tokenAmount <= maxPerMint, "Mint less");
	require(s + _tokenAmount <= maxSupply, "Mint less");
	require(balanceOf(msg.sender) < maxPerWallet, "Mint less per wallet");
	require(msg.value >= price * _tokenAmount, "ETH input is wrong");
  	onWhitelist[msg.sender] = wl - _tokenAmount;
  	delete wl;
	for (uint256 i = 0; i < _tokenAmount; ++i) {
	_safeMint(msg.sender, s + i, "");
	}
	delete s;
	}

	// admin minting
	function gift(uint[] calldata gifts, address[] calldata recipient) external onlyOwner{
	require(gifts.length == recipient.length);
	uint g = 0;
	uint256 s = totalSupply();
	for(uint i = 0; i < gifts.length; ++i){
	g += gifts[i];
	}
	require( s + g <= maxSupply);
	delete g;
	for(uint i = 0; i < recipient.length; ++i){
	for(uint j = 0; j < gifts[i]; ++j){
	_safeMint( recipient[i], s++, "" );
	}
	}
	delete s;	
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
	maxPerMint = _newMaxMintAmount;
	}

	function setMaxPerWallet(uint256 _newMaxPerWalletAmount) public onlyOwner {
	maxPerWallet = _newMaxPerWalletAmount;
	}

	function setURI(string memory _newBaseURI) public onlyOwner {
	baseURI = _newBaseURI;
	}

	function setContractStatus(bool _status) public onlyOwner {
	contractStatus = _status;
	}

	function setWhitelistStatus(bool _whiteliststatus) public onlyOwner {
	whitelistStatus = _whiteliststatus;
	}

	function withdraw() public payable onlyOwner {
	(bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
	require(success);
	}
}