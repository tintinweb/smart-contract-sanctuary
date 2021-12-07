// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;

import './ERC721Enumerable.sol';
import './Ownable.sol';
import './Strings.sol';
import './Payment.sol';
import './Guard.sol';

contract Illuminati is ERC721Enumerable, Ownable, Payment, Guard {
    using Strings for uint256;
    string public baseURI;

  	//settings
  	uint256 public maxSupply = 8128;
	bool public whitelistStatus = false;
	bool public failSafe = false;
	bool public publicStatus = false;
	mapping(address => uint256) public onWhitelist;

  	//prices
	uint256 private price = 0.23 ether;

	//maxmint
	uint256 public maxMint = 2;

	//shares
	address[] private addressList = [
		0xb7118e23C6bFA9eFEC528b31124468D29eaf9AEB, //Illuminati DAO/Collective
	0xb746ef36D3A1672074ED6674A999a097Ec4b606f,
	0x221320D34800760E06B206aCd01e626e463eB03E,
	0x993a69EFE73e3f87df4276E40E81E426385Fd2D8,
	0xEcc03efB7C0A7BD09A5cC7e954Ac42E8f949A0B5,
	0x612819484179821cD76BbDe5b63AE66fb5e50fb5,
	0xfd1494E7EadBD7A4b8C0f7AC098723493F3993a4,
	0x559de301EffC4338b2805f79B4e815F387332d23,
	0xB050bbdcB90f6760c83E4948354e1053FB034673,
	0x0b7D1aFa0Ff0366B6e498E5af5497aAF80e40726
	];
	uint[] private shareList = [50,
								10,
								10,
								10,
								5,
								1,
								1,
								1,
								1,
								11];

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

	// public minting
	function mintPublic(uint256 _tokenAmount) public payable {
	uint256 s = totalSupply();
	require(publicStatus, "Public sale is not active" );
	require(_tokenAmount > 0, "Mint more than 0" );
	require(_tokenAmount <= maxMint, "Mint less");
	require( s + _tokenAmount <= maxSupply, "Mint less");
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
	uint b = balanceOf(msg.sender); // balance

	require(whitelistStatus, "Whitelist is not active" );
	require(_tokenAmount > 0, "Mint more than 0" );
	require(_tokenAmount <= maxMint, "Mint less");
	require( s + _tokenAmount <= maxSupply, "Mint less");
	require(msg.value >= price * _tokenAmount, "ETH input is wrong");
	require(b + _tokenAmount <= maxMint);
  	require(wl > 0);
  	delete b;
	delete wl;
	for (uint256 i = 0; i < _tokenAmount; ++i) {
	_safeMint(msg.sender, s + i, "");
	}
	delete s;
	}

	function mintWhitelistFS(uint256 _tokenAmount) public payable {
	uint256 s = totalSupply();
  	uint256 wl = onWhitelist[msg.sender];

	require(whitelistStatus, "Whitelist is not active" );
	require(failSafe, "Not active" );
	require(_tokenAmount > 0, "Mint more than 0" );
	require(_tokenAmount <= maxMint, "Mint less");
	require( s + _tokenAmount <= maxSupply, "Mint less");
	require(msg.value >= price * _tokenAmount, "ETH input is wrong");
  	require(wl > 0);
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
	require( s + g <= maxSupply, "Too many" );
	delete g;
	for(uint i = 0; i < recipient.length; ++i){
	for(uint j = 0; j < gifts[i]; ++j){
	_safeMint( recipient[i], s++, "" );
	}
	}
	delete s;	
	}
  
    // admin functionality
	function whitelistSet(address[] calldata _addresses) public onlyOwner {
	for(uint256 i; i < _addresses.length; i++){
	onWhitelist[_addresses[i]] = maxMint;
	}
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

	//price switch
	function setPrice(uint256 _newPrice) public onlyOwner {
	price = _newPrice;
	}

	//max switch
	function setMax(uint256 _newMaxMintAmount) public onlyOwner {
	maxMint = _newMaxMintAmount;
	}
	
	//write metadata
	function setURI(string memory _newBaseURI) public onlyOwner {
	baseURI = _newBaseURI;
	}

	//onoff switch

	function setWL(bool _wlstatus) public onlyOwner {
	whitelistStatus = _wlstatus;
	}

	function setP(bool _pstatus) public onlyOwner {
	publicStatus = _pstatus;
	}

	function failsafe(bool _pstatus) public onlyOwner {
	failSafe = _pstatus;
	}

	function withdraw() public payable onlyOwner {
	(bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
	require(success);
	}
}