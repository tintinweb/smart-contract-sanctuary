// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721Enumerable.sol";
import "./ERC721.sol";
import "./Ownable.sol";
import "./ECDSA.sol";
import "./EIP712.sol";
import "./Payment.sol";

contract Contract is ERC721Enumerable,  EIP712, Ownable, Payment {
    using Strings for uint256;
    string public baseURI;

    //merkle signature
    string private constant SINGING_DOMAIN = "TEST";
    string private constant SIGNATURE_VERSION = "4";

    //settings
  	uint256 public maxSupply = 8000;
	bool public whitelistStatus = false;
	bool public publicStatus = false;
	uint256 private price = 0.001 ether;
	uint256 public maxMintPerTx = 5;
    uint256 public maxMintPerWallet = 10;

    //mappings
     mapping(address => uint256) private mintCountMap;
     mapping(address => uint256) private allowedMintCountMap;

    	//shares
	address[] private addressList = [
		0x2349334b6c1Ee1eaF11CBFaD871570ccdF28440e,
	0xdD92ADeA037A7a6206A5e39644F26621D01CE4e4
	];
	uint[] private shareList = [50,
								50];

    constructor(
        	string memory _name,
	string memory _symbol,
	string memory _initBaseURI
    ) 
    ERC721(_name, _symbol) 
    EIP712(SINGING_DOMAIN, SIGNATURE_VERSION) 
    Payment(addressList, shareList) {
          setURI(_initBaseURI); 
    }

    function mintWhitelist(uint256 _tokenAmount, string memory name, bytes memory signature) public payable {
  	uint256 s = totalSupply();
        require(check(name, signature) == msg.sender, "Signature Invalid"); //merkle
        require(whitelistStatus,"Public sale is not active");
        require(_tokenAmount > 0, "Mint more than 0" );
	    require(_tokenAmount <= maxMintPerTx, "Mint less");
	    require( s + _tokenAmount <= maxSupply, "Mint less");
	    require(msg.value >= price * _tokenAmount, "ETH input is wrong");
        require(allowedMintCount(msg.sender) >= 1,"You minted too many");
       for (uint256 i = 0; i < _tokenAmount; ++i) {
       _safeMint(msg.sender, s + i, "");
       	}
           	delete s;
        updateMintCount(msg.sender, _tokenAmount);
    }

    function mintPublic(uint256 _tokenAmount) public payable {
  	uint256 s = totalSupply();
        require(publicStatus,"Public sale is not active");
        require(_tokenAmount > 0, "Mint more than 0" );
	    require(_tokenAmount <= maxMintPerTx, "Mint less");
	    require( s + _tokenAmount <= maxSupply, "Mint less");
	    require(msg.value >= price * _tokenAmount, "ETH input is wrong");
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

    function check(string memory name, bytes memory signature) public view returns (address) {
        return _verify( name, signature);
    }

    function _verify(string memory name, bytes memory signature) internal view returns (address) {
        bytes32 digest = _hash(name);
        return ECDSA.recover(digest, signature);
    }

    function _hash(string memory name) internal view returns (bytes32) {
        return _hashTypedDataV4(keccak256(abi.encode(
            keccak256("Web3Struct(string name)"),
            keccak256(bytes(name))
        )));
        }

    function allowedMintCount(address minter) public view returns (uint256) {
    return maxMintPerWallet - mintCountMap[minter];
     }

    function updateMintCount(address minter, uint256 count) private {
    mintCountMap[minter] += count;
     }

    //price switch
	function setPrice(uint256 _newPrice) public onlyOwner {
	price = _newPrice;
	}

	//max switch
	function setMaxPerTx(uint256 _newMaxMintAmount) public onlyOwner {
	maxMintPerTx = _newMaxMintAmount;
	}

    //max switch
	function setMaxPerWallet(uint256 _newMaxMintAmount) public onlyOwner {
	maxMintPerWallet = _newMaxMintAmount;
	}

    	//onoff switch
	function setWL(bool _wlstatus) public onlyOwner {
	whitelistStatus = _wlstatus;
	}

	function setP(bool _pstatus) public onlyOwner {
	publicStatus = _pstatus;
	}

	//write metadata
	function setURI(string memory _newBaseURI) public onlyOwner {
	baseURI = _newBaseURI;
	}

    	function withdraw() public payable onlyOwner {
	(bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
	require(success);
	}

}