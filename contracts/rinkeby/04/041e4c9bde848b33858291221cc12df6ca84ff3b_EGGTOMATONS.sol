// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;

abstract contract MINTPASS {
  function ownerOf(uint256 tokenId) public virtual view returns (address);
  function tokenOfOwnerByIndex(address owner, uint256 index) public virtual view returns (uint256);
  function balanceOf(address owner) external virtual view returns (uint256 balance);
}

import './ERC721Enumerable.sol';
import './Ownable.sol';
import './Strings.sol';
import './Payment.sol';
import './Guard.sol';

contract EGGTOMATONS is ERC721Enumerable, Ownable, Payment, Guard {
    using Strings for uint256;
    string public baseURI;

	MINTPASS private mintpass;

  	//settings
  	uint256 public maxSupply = 7007;
  	uint256 public mintPassReserve = 500;
  	bool public mintpassStatus = false;
	bool public whitelistStatus = false;
	bool public publicStatus = false;
	mapping(address => uint256) public onWhitelist;

	uint256[] storeClaim;

  	//prices
	uint256 private priceMP = 0.04 ether;
	uint256 private priceWL = 0.04 ether;
	uint256 private priceP1 = 0.05 ether;
	uint256 private priceP2 = 0.045 ether;
	uint256 private priceP3 = 0.04 ether;

	//maxmint
	uint256 public maxMP = 3;
	uint256 public maxWL = 2;
	uint256 public maxP = 10;

	//shares
	address[] private addressList = [
	0xa66FdBCf132c504705aaaE75B117445424563D9d,
	0xf7CE172267d241fC58d8594bc54Ff0D4b6c9fd43,
    0x8D921f72dB4e3ddA7F1B231a42b7E83da7938f58,
	0x10210fBa0f2d584F764C230006FA56FbB94beb31,
	0xEcc03efB7C0A7BD09A5cC7e954Ac42E8f949A0B5
	];
	uint[] private shareList = [20,20,20,35,5];

	//token
	constructor(
	string memory _name,
	string memory _symbol,
	string memory _initBaseURI,
	address mintpassContractAddress
	) 
    ERC721(_name, _symbol)
	    Payment(addressList, shareList){
	    setURI(_initBaseURI);
		mintpass = MINTPASS(mintpassContractAddress);
	}

	// public minting
	function mintPublic(uint256 _tokenAmount) public payable {
	uint256 s = totalSupply() + 1;
	uint256 wl = onWhitelist[msg.sender];
	uint b = mintpass.balanceOf(msg.sender); // MINTPASS balance

	require(publicStatus, "Public sale is not active" );
	require(_tokenAmount > 0, "Mint more than 0" );
	require(_tokenAmount <= maxP, "Mint less");
	require( (s - 1) + _tokenAmount <= maxSupply - mintPassReserve, "Mint less");
	//mint pass or whitelist
	if (b>0) {
	require(msg.value >= priceMP * _tokenAmount, "ETH input is wrong");
	}
	else if (wl>0){
	require(msg.value >= priceWL * _tokenAmount, "ETH input is wrong");
	}
	//public
	else{
	if (_tokenAmount < 5){
	require(msg.value >= priceP1 * _tokenAmount, "ETH input is wrong");
	}
	if (_tokenAmount > 4 && _tokenAmount < 10){
	require(msg.value >= priceP2 * _tokenAmount, "ETH input is wrong");
	}
	if (_tokenAmount == 10){
	require(msg.value >= priceP3 * _tokenAmount, "ETH input is wrong");
	}
	}
	for (uint256 i = 0; i < _tokenAmount; ++i) {
	_safeMint(msg.sender, s + i, "");
	}
	delete s;
	delete b;
	}

	// mintpass minting
	function mintMintPass(uint256 _tokenAmount) public payable {
	uint b = mintpass.balanceOf(msg.sender); // MINTPASS balance
	uint ba = balanceOf(msg.sender); //EGGTOMATONS balance
	uint256 s = totalSupply() + 1;
	require(mintpassStatus, "Mint pass is not active" );
	require(b > 0, "You need a mint pass");
	require(ba + _tokenAmount <= (maxMP * b) + b, "Mint less");
	require( (s - 1) + _tokenAmount <= maxSupply - mintPassReserve, "Mint less");
	require(msg.value >= priceMP * _tokenAmount, "ETH input is wrong");
	delete ba;
	delete b;
	for (uint256 i = 0; i < _tokenAmount ; ++i) {
	_safeMint(msg.sender, s + i, "");
	}
    delete s;
	}

	//check if claim
	function checktheclaim(uint256 n) public view returns (bool) {
    for (uint256 i = 0; i < storeClaim.length; i++) {
        if (storeClaim[i] == n) {
            return true;
    }
    }
    return false;
	}

	// mintpass free claim
	function freeclaim(uint256 tokenID) public {
	uint256 s = totalSupply() + 1;
	require(mintpassStatus, "Mint pass is not active" );
	require( (s - 1) <= maxSupply, "Mint less");
	require( mintpass.ownerOf(tokenID) == msg.sender, "You don't own this token"); //must be owner
	require(checktheclaim(tokenID) == false); //must not be claimed already
	//mint
	_safeMint(msg.sender, s, "");
	storeClaim.push(tokenID);
    delete s;
	}


	// whitelist minting
	function mintWhitelist(uint256 _tokenAmount) public payable {
	uint256 s = totalSupply() + 1;
  	uint256 wl = onWhitelist[msg.sender];
	uint ba = balanceOf(msg.sender); //EGGTOMATONS balance
	require(whitelistStatus, "Whitelist is not active" );
	require(_tokenAmount > 0, "Mint more than 0" );
	require(ba + _tokenAmount <= maxWL, "Mint less");
	require( (s - 1) + _tokenAmount <= maxSupply - mintPassReserve, "Mint less");
	require(msg.value >= priceWL * _tokenAmount, "ETH input is wrong");
  	require(wl > 0);
  	delete wl;
	delete ba;
	for (uint256 i = 0; i < _tokenAmount; ++i) {
	_safeMint(msg.sender, s + i, "");
	}
	delete s;
	}

	// admin minting
	function gift(uint[] calldata gifts, address[] calldata recipient) external onlyOwner{
	require(gifts.length == recipient.length);
	uint g = 0;
	uint256 s = totalSupply() + 1;
	for(uint i = 0; i < gifts.length; ++i){
	g += gifts[i];
	}
	require( (s - 1) + g <= maxSupply, "Too many" );
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
	onWhitelist[_addresses[i]] = maxWL;
	}
	}


	//read metadata
	function _baseURI() internal view virtual returns (string memory) {
	return baseURI;
	}

	function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
	require(tokenId > 0);
	require(tokenId <= maxSupply);
	string memory currentBaseURI = _baseURI();
	return bytes(currentBaseURI).length > 0	? string(abi.encodePacked(currentBaseURI, tokenId.toString())) : "";
	}

	//price switch
	function setPriceMP(uint256 _newPrice) public onlyOwner {
	priceMP = _newPrice;
	}
	function setPriceWL(uint256 _newPrice) public onlyOwner {
	priceWL = _newPrice;
	}
	function setPriceP1(uint256 _newPrice) public onlyOwner {
	priceP1 = _newPrice;
	}
	function setPriceP2(uint256 _newPrice) public onlyOwner {
	priceP2 = _newPrice;
	}
	function setPriceP3(uint256 _newPrice) public onlyOwner {
	priceP3 = _newPrice;
	}

	//max switch
	function setMaxMP(uint256 _newMaxMintAmount) public onlyOwner {
	maxMP = _newMaxMintAmount;
	}
	function setMaxWL(uint256 _newMaxMintAmount) public onlyOwner {
	maxWL = _newMaxMintAmount;
	}
	function setMaxP(uint256 _newMaxMintAmount) public onlyOwner {
	maxP = _newMaxMintAmount;
	}
	function changeReserve(uint256 _newReserveAmount) public onlyOwner {
	mintPassReserve = _newReserveAmount;
	}
	
	//write metadata
	function setURI(string memory _newBaseURI) public onlyOwner {
	baseURI = _newBaseURI;
	}

	//onoff switch
	function setMP(bool _mpstatus) public onlyOwner {
	mintpassStatus = _mpstatus;
	}

	function setWL(bool _wlstatus) public onlyOwner {
	whitelistStatus = _wlstatus;
	}

	function setP(bool _pstatus) public onlyOwner {
	publicStatus = _pstatus;
	}

	function withdraw() public payable onlyOwner {
	(bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
	require(success);
	}
}