// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import './ERC721Enumerable.sol';
import './Ownable.sol';
import './Strings.sol';
import './Payment.sol';
import './Guard.sol';
import './IERC20.sol';
import './IERC1155.sol';

abstract contract ERC1155 {
    function balanceOf(address account) public view virtual returns (uint256);
}

abstract contract ERC1155Token {
    function balanceOf(address account, uint256 id) public view virtual returns (uint256);
}

abstract contract ERC20 {
    function balanceOf(address account) public view virtual returns (uint256);
}

contract TestTriangle is ERC721Enumerable, Ownable, Payment, Guard {
    using Strings for uint256;
    string public baseURI;

  	//settings
  	uint256 public maxSupply = 8121;
  	uint256 private maxMint = 2;
  	uint256 private price = 0.01 ether;

	//phase limits
	uint256 private maxIndunction = 1500;
	uint256 private maxPhase1 = 2000;
	uint256 private maxPhase2 = 1000;
	uint256 private maxPhase3 = 500;
	uint256 private maxPhase4 = 500;

	//phase counters
	uint256 public IndunctionReserveCount;
    uint256 public phase1ReserveCount;
	uint256 public phase2ReserveCount;
	uint256 public phase3ReserveCount;
	uint256 public phase4ReserveCount;

	//buttons
	bool public indunctionStatus = false;
	bool public reserveStatus = false;
	bool public publicStatus = false;
	bool public phase1 = false;
	bool public phase2 = false;
	bool public phase3 = false;
	bool public phase4 = false;

	//mappings
	mapping(address => uint256) public onReserveList;
	mapping(address => uint256) public onWhitelist;
	mapping(address => uint256) private _reserved;
	mapping (address => uint256) authorizedContractERC1155;
	mapping (address => uint256) authorizedContractERC721;
	mapping (address => uint256) authorizedContractERC20;

	address[] private addressList = [
	0x2349334b6c1Ee1eaF11CBFaD871570ccdF28440e
	];
	uint[] private shareList = [100];
  
	constructor(
	string memory _name,
	string memory _symbol,
	string memory _initBaseURI
	) 
    ERC721(_name, _symbol)
	    Payment(addressList, shareList){
	    setURI(_initBaseURI);
	}

	//minting 
	function mintReserved( uint256 _tokenAmount) public payable {
	uint256 s = totalSupply();
	uint256 wl = onWhitelist[msg.sender];
	uint256 r = onReserveList[msg.sender];
    uint256 ba = balanceOf(msg.sender);
	require(wl > 0 || r > 0,"Did not pass the gate, yet.");
	require(reserveStatus,"Phase is not live yet");
	require(_tokenAmount > 0, "Mint more than 0." );
	require(msg.value >= price * _tokenAmount, "ETH input is wrong.");
	require(_tokenAmount <= maxMint,"Mint less.");
    require(ba <= maxMint,"This wallet is maxed out");
	delete wl;
	delete r;
	for (uint256 i = 0; i < _tokenAmount; ++i) {
	_safeMint(msg.sender, s + i, "");
	}
	delete s;
	}

	//minting Metaverse HQ
	function mintIndunction( uint256 _tokenAmount) public payable {
	uint256 s = totalSupply();
	uint256 ba = balanceOf(msg.sender);
	address contractAddressHash = 0x88B48F654c30e99bc2e4A1559b4Dcf1aD93FA656;
	uint256 tokenid = 15960283558589263824374976046742912375398974364952532521510328477544542633985;
	ERC1155Token contractAddressToken = ERC1155Token(contractAddressHash);
    require(contractAddressToken.balanceOf(msg.sender,tokenid) > 0, "Doesn't own the token");
	require(indunctionStatus,"Phase is not live yet");
	require(_tokenAmount > 0, "Mint more than 0." );
	require(msg.value >= price * _tokenAmount, "ETH input is wrong.");
	require(_tokenAmount <= maxMint,"Mint less.");
	require(ba <= maxMint,"This wallet is maxed out");
	require(IndunctionReserveCount <= maxIndunction * maxMint,"Indunction Phase max reached");
	for (uint256 i = 0; i < _tokenAmount; ++i) {
	_safeMint(msg.sender, s + i, "");
	IndunctionReserveCount += 1;
	}
	delete s;
	}

    //minting 
	function mintPublic( uint256 _tokenAmount) public payable {
	uint256 s = totalSupply();
	require(publicStatus,"Public sale is not live");
	require(_tokenAmount > 0, "Mint more than 0." );
	require(msg.value >= price * _tokenAmount, "ETH input is wrong.");
	require(_tokenAmount <= maxMint,"Mint less.");
	for (uint256 i = 0; i < _tokenAmount; ++i) {
	_safeMint(msg.sender, s + i, "");
	}
	delete s;
	}

	// whitelist
	function whitelistSet(address[] calldata _addresses) public onlyOwner {
	for(uint256 i; i < _addresses.length; i++){
	onWhitelist[_addresses[i]] = maxMint;
	}
	}

	//phase 1 reserve
	function reservePhase1(address _address, address contractAddressHash, uint256 contractType) public {
	
	//phase active
	require(phase1,"Phase is not live yet");
	
	//check if address already reserved
	require(_reserved[msg.sender] == 0,"Already Reserved");

	//check reserve limit
	require(phase1ReserveCount <= maxPhase1, "Phase limit has been hit");
	
	//ERC1155 check
	if(contractType == 1155){
	ERC1155 contractAddress = ERC1155(contractAddressHash);
    require(contractAddress.balanceOf(msg.sender) > 0, "Doesn't own the token");
	require(authorizedContractERC1155[contractAddressHash] > 0, "Contract is not gatekeeped");
	onReserveList[_address] = maxMint;
	}
	//ERC721 check
	if(contractType == 721){
	ERC721 contractAddress = ERC721(contractAddressHash);
    require(contractAddress.balanceOf(msg.sender) > 0, "Doesn't own the token");
	require(authorizedContractERC721[contractAddressHash] > 0, "Contract is not gatekeeped");
	onReserveList[_address] = maxMint;
	}
	//ERC20 check
	if(contractType == 20){
	ERC20 contractAddress = ERC20(contractAddressHash);
    require(contractAddress.balanceOf(msg.sender) > 0, "Doesn't own the token");
	require(authorizedContractERC20[contractAddressHash] > 0, "Contract is not gatekeeped");
	onReserveList[_address] = maxMint;
	}
	_reserved[msg.sender] += 1;
	phase1ReserveCount += 1;
	}

	//phase 2 reserve
	function reservePhase2(address _address, address contractAddressHash, uint256 contractType) public {
	
	//phase active
	require(phase2,"Phase is not live yet");
	
	//check if address already reserved
	require(_reserved[msg.sender] == 0,"Already Reserved");

	//check reserve limit
	require(phase2ReserveCount <= maxPhase1, "Phase limit has been hit");
	
	//ERC1155 check
	if(contractType == 1155){
	ERC1155 contractAddress = ERC1155(contractAddressHash);
    require(contractAddress.balanceOf(msg.sender) > 0, "Doesn't own the token");
	require(authorizedContractERC1155[contractAddressHash] > 0, "Contract is not gatekeeped");
	onReserveList[_address] = maxMint;
	}
	//ERC721 check
	if(contractType == 721){
	ERC721 contractAddress = ERC721(contractAddressHash);
    require(contractAddress.balanceOf(msg.sender) > 0, "Doesn't own the token");
	require(authorizedContractERC721[contractAddressHash] > 0, "Contract is not gatekeeped");
	onReserveList[_address] = maxMint;
	}
	//ERC20 check
	if(contractType == 20){
	ERC20 contractAddress = ERC20(contractAddressHash);
    require(contractAddress.balanceOf(msg.sender) > 0, "Doesn't own the token");
	require(authorizedContractERC20[contractAddressHash] > 0, "Contract is not gatekeeped");
	onReserveList[_address] = maxMint;
	}
	_reserved[msg.sender] += 1;
	phase2ReserveCount += 1;
	}

	//phase 3 reserve
	function reservePhase3(address _address, address contractAddressHash, uint256 contractType) public {
	
	//phase active
	require(phase3,"Phase is not live yet");
	
	//check if address already reserved
	require(_reserved[msg.sender] == 0,"Already Reserved");

	//check reserve limit
	require(phase3ReserveCount <= maxPhase1, "Phase limit has been hit");
	
	//ERC1155 check
	if(contractType == 1155){
	ERC1155 contractAddress = ERC1155(contractAddressHash);
    require(contractAddress.balanceOf(msg.sender) > 0, "Doesn't own the token");
	require(authorizedContractERC1155[contractAddressHash] > 0, "Contract is not gatekeeped");
	onReserveList[_address] = maxMint;
	}
	//ERC721 check
	if(contractType == 721){
	ERC721 contractAddress = ERC721(contractAddressHash);
    require(contractAddress.balanceOf(msg.sender) > 0, "Doesn't own the token");
	require(authorizedContractERC721[contractAddressHash] > 0, "Contract is not gatekeeped");
	onReserveList[_address] = maxMint;
	}
	//ERC20 check
	if(contractType == 20){
	ERC20 contractAddress = ERC20(contractAddressHash);
    require(contractAddress.balanceOf(msg.sender) > 0, "Doesn't own the token");
	require(authorizedContractERC20[contractAddressHash] > 0, "Contract is not gatekeeped");
	onReserveList[_address] = maxMint;
	}
	_reserved[msg.sender] += 1;
	phase3ReserveCount += 1;
	}

	//phase 4 reserve
	function reservePhase4(address _address, address contractAddressHash, uint256 contractType) public {
	
	//phase active
	require(phase4,"Phase is not live yet");
	
	//check if address already reserved
	require(_reserved[msg.sender] == 0,"Already Reserved");

	//check reserve limit
	require(phase4ReserveCount <= maxPhase1, "Phase limit has been hit");
	
	//ERC1155 check
	if(contractType == 1155){
	ERC1155 contractAddress = ERC1155(contractAddressHash);
    require(contractAddress.balanceOf(msg.sender) > 0, "Doesn't own the token");
	require(authorizedContractERC1155[contractAddressHash] > 0, "Contract is not gatekeeped");
	onReserveList[_address] = maxMint;
	}
	//ERC721 check
	if(contractType == 721){
	ERC721 contractAddress = ERC721(contractAddressHash);
    require(contractAddress.balanceOf(msg.sender) > 0, "Doesn't own the token");
	require(authorizedContractERC721[contractAddressHash] > 0, "Contract is not gatekeeped");
	onReserveList[_address] = maxMint;
	}
	//ERC20 check
	if(contractType == 20){
	ERC20 contractAddress = ERC20(contractAddressHash);
    require(contractAddress.balanceOf(msg.sender) > 0, "Doesn't own the token");
	require(authorizedContractERC20[contractAddressHash] > 0, "Contract is not gatekeeped");
	onReserveList[_address] = maxMint;
	}
	_reserved[msg.sender] += 1;
	phase4ReserveCount += 1;
	}

    // Check if an address already reserved
	function reserved(address owner) public view  returns (uint256){
    require(owner != address(0), 'Zero address');
    return _reserved[owner];
    }

	// Authorize specific ERC1155 smart contract
    function toggleContractAuthorizationERC1155(address contractAddress) public onlyOwner {
        authorizedContractERC1155[contractAddress] = 1;
    }
    // Check if a ERC1155 contract address is authorized to reserve/mint
    function isERC1155ContractAuthorized(address contractAddress) view public returns(uint256) {
        return authorizedContractERC1155[contractAddress];
    }

	// Authorize specific ERC721 smart contract
    function toggleContractAuthorizationERC721(address contractAddress) public onlyOwner {
        authorizedContractERC721[contractAddress] = 1;
    }
    // Check if a ERC721 contract address is authorized to reserve/mint
    function isERC721ContractAuthorized(address contractAddress) view public returns(uint256) {
        return authorizedContractERC721[contractAddress];
    }

	// Authorize specific ERC20 smart contract
    function toggleContractAuthorizationERC20(address contractAddress) public onlyOwner {
        authorizedContractERC20[contractAddress] = 1;
    }
    // Check if a ERC20 contract address is authorized to reserve/mint
    function isERC20ContractAuthorized(address contractAddress) view public returns(uint256) {
        return authorizedContractERC20[contractAddress];
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

	function setmaxMint(uint256 _newMaxMint) public onlyOwner {
	maxMint = _newMaxMint;
	}

	function setURI(string memory _newBaseURI) public onlyOwner {
	baseURI = _newBaseURI;
	}

	function publicSwitch(bool _status) public onlyOwner {
	publicStatus = _status;
	}

	function indunctionSwitch(bool _status) public onlyOwner {
	indunctionStatus = _status;
	}

	function reserveSwitch(bool _status) public onlyOwner {
	reserveStatus = _status;
	}

	function phase1switch(bool _status) public onlyOwner {
	phase1 = _status;
	}

	function phase2switch(bool _status) public onlyOwner {
	phase2 = _status;
	}

	function phase3switch(bool _status) public onlyOwner {
	phase3 = _status;
	}

	function phase4switch(bool _status) public onlyOwner {
	phase4 = _status;
	}

	function setindunctionmax(uint256 _newMax) public onlyOwner {
	maxIndunction = _newMax;
	}

	function setphase1max(uint256 _newMax) public onlyOwner {
	maxPhase1 = _newMax;
	}

	function setphase2max(uint256 _newMax) public onlyOwner {
	maxPhase2 = _newMax;
	}

	function setphase3max(uint256 _newMax) public onlyOwner {
	maxPhase3 = _newMax;
	}

	function setphase4max(uint256 _newMax) public onlyOwner {
	maxPhase4 = _newMax;
	}	

	function withdraw() public payable onlyOwner {
	(bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
	require(success);
	}
}