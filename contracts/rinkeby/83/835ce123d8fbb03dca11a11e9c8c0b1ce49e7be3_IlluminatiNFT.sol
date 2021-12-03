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

abstract contract ERC20 {
    function balanceOf(address account) public view virtual returns (uint256);
}

contract IlluminatiNFT is ERC721Enumerable, Ownable, Payment, Guard {
    using Strings for uint256;
    string public baseURI;

  	//settings
  	uint256 public maxSupply = 8121;
  	uint256 public maxMintWL = 2;
	uint256 public maxMintPublic = 2;
  	uint256 private price = 0.2 ether;
  	bool public publicStatus = false;
	bool public whitelistStatus = false;

	//mappings
	mapping(address => uint256) public onReserveList;
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


	// test minting dependency
	function mintWhitelist( uint256 _tokenAmount) public payable {
	uint256 s = totalSupply();

	require(_tokenAmount > 0, "Mint more than 0" );
	require(msg.value >= price * _tokenAmount, "ETH input is wrong");

	for (uint256 i = 0; i < _tokenAmount; ++i) {
	_safeMint(msg.sender, s + i, "");
	}
	delete s;
	}


	//reserve functionality
	function reserveSet(address _address, address contractAddressHash, uint256 contractType) public {
	//check if address already reserved
	require(_reserved[msg.sender] == 0,"Already Reserved");

	//ERC1155 check
	if(contractType == 1155){
	ERC1155 contractAddress = ERC1155(contractAddressHash);
    require(contractAddress.balanceOf(msg.sender) > 0, "Doesn't own the token");
	require(authorizedContractERC1155[contractAddressHash] > 0, "Contract is not gatekeeped");
	onReserveList[_address] = maxMintWL;
	}
	//ERC721 check
	if(contractType == 721){
	ERC721 contractAddress = ERC721(contractAddressHash);
    require(contractAddress.balanceOf(msg.sender) > 0, "Doesn't own the token");
	require(authorizedContractERC721[contractAddressHash] > 0, "Contract is not gatekeeped");
	onReserveList[_address] = maxMintWL;
	}
	//ERC20 check
	if(contractType == 20){
	ERC20 contractAddress = ERC20(contractAddressHash);
    require(contractAddress.balanceOf(msg.sender) > 0, "Doesn't own the token");
	require(authorizedContractERC20[contractAddressHash] > 0, "Contract is not gatekeeped");
	onReserveList[_address] = maxMintWL;
	}
	_reserved[msg.sender] += 1;
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
        return authorizedContractERC20[contractAddress];
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

	function setMaxMintWL(uint256 _newMaxMintAmount) public onlyOwner {
	maxMintWL = _newMaxMintAmount;
	}

	function setMaxMintPublic(uint256 _newMaxMintAmount) public onlyOwner {
	maxMintPublic = _newMaxMintAmount;
	}

	function setURI(string memory _newBaseURI) public onlyOwner {
	baseURI = _newBaseURI;
	}

	function setPublicStatus(bool _status) public onlyOwner {
	publicStatus = _status;
	}

	function setWhitelistStatus(bool _status) public onlyOwner {
	whitelistStatus = _status;
	}

	function withdraw() public payable onlyOwner {
	(bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
	require(success);
	}
}