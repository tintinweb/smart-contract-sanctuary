// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;

abstract contract OG {
  function ownerOf(uint256 tokenId) public virtual view returns (address);
  function tokenOfOwnerByIndex(address owner, uint256 index) public virtual view returns (uint256);
  function balanceOf(address owner) external virtual view returns (uint256 balance);
}

import './ERC721Enumerable.sol';
import './Ownable.sol';
import './Strings.sol';
import './Payment.sol';
import './Guard.sol';

contract BeardBears is ERC721Enumerable, Ownable, Payment, Guard {
    using Strings for uint256;
    string public baseURI;

    OG private og;

  	//settings
  	uint256 public maxSupply = 10000;
	bool public OGStatus = false;
	bool public whitelistStatus = false;
	bool public whitelist2Status = false;
	bool public publicStatus = false;
	bool public communityStatus = false;
	mapping(address => uint256) public onWhitelist;
	mapping(address => uint256) public onWhitelist2;
	mapping(address => uint256) public purchaseWL;
	mapping(address => uint256) public purchaseWL2;

  	//prices
	uint256 private price = 0.0888 ether;

	//maxmint
	uint256 public maxMintOG = 20;
	uint256 public maxMintWL = 5;
	uint256 public maxMintWL2 = 2;
	uint256 public maxMintPublic = 5;
	uint256 public transactionLimit = 1;
	uint256 public OGtransactionLimit = 1;

	//shares
	address[] private addressList = [
		0x3Ae370AcD5Fe41D40A484007EEdF8A060A6c210D
	];
	uint[] private shareList = [100];

	//token
	constructor(
	string memory _name,
	string memory _symbol,
	string memory _initBaseURI,
    address ogaddr
	) 
    ERC721(_name, _symbol)
	    Payment(addressList, shareList){
	    setURI(_initBaseURI);
        og = OG(ogaddr);
	}

	// public minting
	function mintPublic(uint256 _tokenAmount) public payable {
	uint256 s = totalSupply();
	require(publicStatus, "Public sale is not active" );
	require(_tokenAmount <= maxMintPublic, "Mint less");
	require( s + _tokenAmount <= maxSupply, "Mint less");
	require(msg.value >= price * _tokenAmount, "ETH input is wrong");
	for (uint256 i = 0; i < _tokenAmount; ++i) {
	_safeMint(msg.sender, s + i, "");
	}
	delete s;
	}

	// og minting
	function mintOG(uint256 _tokenAmount) public payable {
	uint o = og.balanceOf(msg.sender);
	uint256 s = totalSupply();
	require(OGStatus, "Whitelist is not active" );
	require(o > 0);
	require(_tokenAmount <= (maxMintOG * o), "Mint less");
	require( s + _tokenAmount <= maxSupply, "Mint less");
	require(msg.value >= price * _tokenAmount, "ETH input is wrong");
	delete o;
	for (uint256 i = 0; i < _tokenAmount; ++i) {
	_safeMint(msg.sender, s + i, "");
	}
	delete s;
	}

	// whitelist minting
	function mintWhitelist(uint256 _tokenAmount) public payable  {
	uint256 s = totalSupply();
    uint256 wl = onWhitelist[msg.sender];
	require(whitelistStatus, "Whitelist is not active" );
	require(wl > 0);
	require(_tokenAmount <= wl, "Try less");
	require(_tokenAmount <= maxMintWL, "Mint less");
	require(s + _tokenAmount <= maxSupply, "Mint less");
	require(msg.value >= price * _tokenAmount, "ETH input is wrong");
	delete wl;
	for (uint256 i = 0; i < _tokenAmount; ++i) {
	_safeMint(msg.sender, s + i, "");
	}
	delete s;
	}

	// communityWL hash
	function communityWL(uint256 _tokenAmount) public payable {
	uint256 s = totalSupply();
	require(communityStatus, "CommunityWL is not active" );
	require(_tokenAmount <= maxMintWL, "Mint less");
	require(s + _tokenAmount <= maxSupply, "Mint less");
	require(msg.value >= price * _tokenAmount, "ETH input is wrong");
	for (uint256 i = 0; i < _tokenAmount; ++i) {
	_safeMint(msg.sender, s + i, "");
	}
	delete s;
	}

	// whitelist2 minting
	function mintWhitelist2(uint256 _tokenAmount) public payable  {
	uint256 s = totalSupply();
    uint256 wl2 = onWhitelist2[msg.sender];
	require(whitelist2Status, "Whitelist is not active" );
	require(wl2 > 0);
	require(_tokenAmount <= maxMintWL2, "Mint less");
	require( s + _tokenAmount <= maxSupply, "Mint less");
	require(msg.value >= price * _tokenAmount, "ETH input is wrong");
	delete wl2;
	for (uint256 i = 0; i < _tokenAmount; ++i) {
	_safeMint(msg.sender, s + i, "");
	}
	delete s;
	}

	// admin minting
	function gift(uint[] calldata gifts, address[] calldata recipient) external onlyOwner {
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
	onWhitelist[_addresses[i]] = maxMintWL;
	}
	}

	 // admin functionality
	function whitelistSet2(address[] calldata _addresses) public onlyOwner {
	for(uint256 i; i < _addresses.length; i++){
	onWhitelist2[_addresses[i]] = maxMintWL2;
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

	//max switch OG
	function setMaxOG(uint256 _newMaxMintAmount) public onlyOwner {
	maxMintOG = _newMaxMintAmount;
	}

	function setTransactionLimit(uint256 _newLimit) public onlyOwner {
	transactionLimit = _newLimit;
	}

	function setOGTransactionLimit(uint256 _newLimit) public onlyOwner {
	OGtransactionLimit = _newLimit;
	}

	//max switch WL
	function setMaxWL(uint256 _newMaxMintAmount) public onlyOwner {
	maxMintWL = _newMaxMintAmount;
	}

	//max switch WL2
	function setMaxWL2(uint256 _newMaxMintAmount) public onlyOwner {
	maxMintWL2 = _newMaxMintAmount;
	}

	//max switch Public
	function setMaxPublic(uint256 _newMaxMintAmount) public onlyOwner {
	maxMintPublic = _newMaxMintAmount;
	}

	//write metadata
	function setURI(string memory _newBaseURI) public onlyOwner {
	baseURI = _newBaseURI;
	}

	//onoff switch
	function setOG(bool _status) public onlyOwner {
	OGStatus = _status;
	}

	function setWL(bool _status) public onlyOwner {
	whitelistStatus = _status;
	}

	function setCommunity(bool _status) public onlyOwner {
	communityStatus = _status;
	}

	function setWL2(bool _status) public onlyOwner {
	whitelist2Status = _status;
	}

	function setP(bool _status) public onlyOwner {
	publicStatus = _status;
	}

	function withdraw() public payable onlyOwner {
	(bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
	require(success);
	}
}