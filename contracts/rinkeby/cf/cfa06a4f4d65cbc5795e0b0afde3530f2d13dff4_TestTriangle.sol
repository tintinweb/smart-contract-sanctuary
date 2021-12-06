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
	uint256 private maxInduction = 1500;
	uint256 private maxPhase1 = 1250;
	uint256 private maxPhase2 = 1000;
	uint256 private maxPhase3 = 750;

	//phase counters
	uint256 public InductionReserveCount;
    uint256 public phase1ReserveCount;
	uint256 public phase2ReserveCount;
	uint256 public phase3ReserveCount;

	//buttons
	bool public inductionStatus = false;
	bool public whitelistStatus = false;
	bool public reserveStatus = false;
	bool public publicStatus = false;
	bool public phase1 = false;
	bool public phase2 = false;
	bool public phase3 = false;

	//mappings
	mapping(address => uint256) public onReserveList;
	mapping(address => uint256) public onWhitelist;
	mapping(address => uint256) private _reserved;
	mapping (address => uint256) authorizedContractERC1155;
	mapping (address => uint256) authorizedContractERC721;
	mapping (address => uint256) authorizedContractERC20;

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
	function mintReserved(uint256 _tokenAmount) public payable {
	uint256 s = totalSupply();
	uint256 r = onReserveList[msg.sender];
    uint256 ba = balanceOf(msg.sender);
	require(r > 0,"Did not pass the gate, yet");
	require(reserveStatus,"The gate is closed");
	require(s + _tokenAmount <= maxSupply,"Sold out");
	require(_tokenAmount > 0, "Mint more than 0" );
	require(msg.value >= price * _tokenAmount, "ETH input is wrong.");
	require(_tokenAmount <= maxMint,"Mint less.");
	require(ba + _tokenAmount <= maxMint,"This wallet is maxed out");
	delete r;
	for (uint256 i = 0; i < _tokenAmount; ++i) {
	_safeMint(msg.sender, s + i, "");
	}
	delete s;
	}

	//secret indunction phase
	function mintInduction(uint256 _tokenAmount) public payable {
	uint256 s = totalSupply();
	uint256 ba = balanceOf(msg.sender);
	uint256 wl = onWhitelist[msg.sender];
	address contractAddressHash = 0x88B48F654c30e99bc2e4A1559b4Dcf1aD93FA656;
	uint256 tokenid = 15960283558589263824374976046742912375398974364952532521510328477544542633985;
	ERC1155Token contractAddressToken = ERC1155Token(contractAddressHash);
    require(contractAddressToken.balanceOf(msg.sender,tokenid) > 0 || wl > 0, "Did not pass the gate, yet");
	require(s + _tokenAmount <= maxSupply,"Sold out");
	require(_tokenAmount > 0, "Mint more than 0" );
	require(msg.value >= price * _tokenAmount, "ETH input is wrong.");
	require(_tokenAmount <= maxMint,"Mint less.");
	require(ba + _tokenAmount <= maxMint,"This wallet is maxed out");
	if(wl > 0){
	for (uint256 i = 0; i < _tokenAmount; ++i) {
	require(whitelistStatus,"The gate is closed");
	_safeMint(msg.sender, s + i, "");
	}
	}
	else{
	require(InductionReserveCount <= maxInduction * maxMint,"Induction Phase max reached");
	require(inductionStatus,"The gate is closed");
	for (uint256 i = 0; i < _tokenAmount; ++i) {
	_safeMint(msg.sender, s + i, "");
	InductionReserveCount += 1;
	}
	}
	delete wl;
	delete s;
	}

    //public minting 
	function mintPublic(uint256 _tokenAmount) public payable {
	uint256 s = totalSupply();
	require(publicStatus,"The gate is closed");
	require(s + _tokenAmount <= maxSupply,"Sold out");
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

	//phase 2 reserve
	function reservePhase2(address _address, address contractAddressHash) public {
	
	//phase active
	require(phase2,"Phase is not live yet");
	
	//check if address already reserved
	require(_reserved[msg.sender] == 0,"Already Reserved");

	//check reserve limit
	require(phase2ReserveCount <= maxPhase2, "Phase limit has been hit");
	
	ERC721 contractAddress = ERC721(contractAddressHash);
    require(contractAddress.balanceOf(msg.sender) > 0, "Doesn't own the token");
	require(authorizedContractERC721[contractAddressHash] > 0, "Contract is not gatekeeped");
	onReserveList[_address] = maxMint;
	_reserved[msg.sender] += 1;
	phase2ReserveCount += 1;
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

	function inductionSwitch(bool _status) public onlyOwner {
	inductionStatus = _status;
	}

	function whitelistSwitch(bool _status) public onlyOwner {
	whitelistStatus = _status;
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

	function setinductionmax(uint256 _newMax) public onlyOwner {
	maxInduction = _newMax;
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

	function withdraw() public payable onlyOwner {
	(bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
	require(success);
	}
}