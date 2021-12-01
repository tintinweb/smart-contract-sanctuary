// SPDX-License-Identifier: GPL-3.0
// Author: Organixoftware; Developed by Organic Software Solutions, LLC. 2021
pragma solidity ^0.8.10;
import "./ERC721Enum.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./PaymentSplitter.sol";
import "./ReentrancyGuard.sol";

contract OGXTreasureTokens is ERC721Enum, Ownable, PaymentSplitter, ReentrancyGuard {
	using Strings for uint256;
	string public baseURI;
	
    //sale settings
	uint256 public cost = 0.042 ether;
	uint256 public maxSupply = 4200;
	uint256 public maxMint = 20;
	bool public status = false;
	
    //presale settings
	uint256 public presaleDate = 1637132400;
	mapping(address => uint256) public presaleWhitelist;
	
    //share settings
	address[] private addressList = [
        0x31c9B69f00B1424744212Cb4481b5b082dD737C4,
        0x5c7fF1ddA8afAe1c2FB0bAC764e76F7727243408
	];
	uint[] private shareList = [20,80];
	
    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI
	) ERC721P(_name, _symbol) PaymentSplitter( addressList, shareList ){
	    setBaseURI(_initBaseURI);
	}
	
    // internal
	function _baseURI() internal view virtual returns (string memory) {
	    return baseURI;
	}
	
    // public minting
	function mint(uint256 _mintAmount) public payable nonReentrant{
        uint256 s = totalSupply();
        require(status, "Off" );
        require(_mintAmount > 0, "Duh" );
        require(_mintAmount <= maxMint, "Too many" );
        require(s + _mintAmount <= maxSupply, "Sorry" );
        require(msg.value >= cost * _mintAmount);
        for (uint256 i = 0; i < _mintAmount; ++i) {
            _safeMint(msg.sender, s + i, "");
        }
        delete s;
	}

	function mintPresale(uint256 _mintAmount) public payable {
        require(presaleDate <= block.timestamp, "Not yet");
        uint256 s = totalSupply();
        uint256 reserve = presaleWhitelist[msg.sender];
        require(!status, "Off");
        require(reserve > 0, "Low reserve");
        require(_mintAmount <= reserve, "Try less");
        require(s + _mintAmount <= maxSupply, "More than max");
        require(cost * _mintAmount == msg.value, "Wrong amount");
        presaleWhitelist[msg.sender] = reserve - _mintAmount;
        delete reserve;
        for(uint256 i; i < _mintAmount; i++){
            _safeMint(msg.sender, s + i, "");
        }
        delete s;
	}

	// admin minting
	function gift(uint[] calldata quantity, address[] calldata recipient) external onlyOwner{
	require(quantity.length == recipient.length, "Provide quantities and recipients" );
        uint totalQuantity = 0;
        uint256 s = totalSupply();
        for(uint i = 0; i < quantity.length; ++i){
            totalQuantity += quantity[i];
        }
        require( s + totalQuantity <= maxSupply, "Too many" );
        delete totalQuantity;
        for(uint i = 0; i < recipient.length; ++i){
            for(uint j = 0; j < quantity[i]; ++j){
                _safeMint( recipient[i], s++, "" );
            }
        }
        delete s;	
	}
	
    // admin functionality
	function presaleSet(address[] calldata _addresses, uint256[] calldata _amounts) public onlyOwner {
	    for(uint256 i; i < _addresses.length; i++){
            presaleWhitelist[_addresses[i]] = _amounts[i];
        }
	}

	function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
	    require(_exists(tokenId), "ERC721Metadata: Nonexistent token");
	    string memory currentBaseURI = _baseURI();
	    return bytes(currentBaseURI).length > 0	? string(abi.encodePacked(currentBaseURI, tokenId.toString())) : "";
	}

	function setCost(uint256 _newCost) public onlyOwner {
	    cost = _newCost;
	}

	function setMaxMintAmount(uint256 _newMaxMintAmount) public onlyOwner {
	    maxMint = _newMaxMintAmount;
	}

	function setmaxSupply(uint256 _newMaxSupply) public onlyOwner {
	    maxSupply = _newMaxSupply;
	}

	function setBaseURI(string memory _newBaseURI) public onlyOwner {
	    baseURI = _newBaseURI;
	}

	function setSaleStatus(bool _status) public onlyOwner {
	    status = _status;
	}

	function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success);
	}
}