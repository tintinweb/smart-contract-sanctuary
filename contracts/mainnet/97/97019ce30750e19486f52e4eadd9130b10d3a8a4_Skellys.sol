// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ECDSA.sol";
import "./EIP712.sol";
import "./Payment.sol";

contract Skellys is ERC721Enumerable,  EIP712, Ownable, Payment {
    using Strings for uint256;
    string public baseURI;

    //signature
    string private constant SINGING_DOMAIN = "SKELLYS";
    string private constant SIGNATURE_VERSION = "1";

    //settings
  	uint256 public maxSupply = 2500;
	bool public whitelistStatus = false;
	bool public publicStatus = false;
	uint256 private price = 0.04 ether;
	uint256 public maxMintPerTxPublic = 5;
	uint256 public maxMintPerTxWhitelist = 5;
    uint256 public maxMintPerWallet = 5;

    //mappings
     mapping(address => uint256) private mintCountMap;
     mapping(address => uint256) private allowedMintCountMap;

    	//shares
	address[] private addressList = [
		0x85743E23cA846eb1c603413dD4045F977E7d86CF,
		0xEcc03efB7C0A7BD09A5cC7e954Ac42E8f949A0B5
	];
	uint[] private shareList = [75,
    							25];

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
        require(check(name, signature) == msg.sender, "Signature Invalid"); //server side signature
        require(whitelistStatus,"Whitelist sale is not active");
        require(_tokenAmount > 0, "Mint more than 0" );
	    require(_tokenAmount <= maxMintPerTxWhitelist, "Mint less");
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
	    require(_tokenAmount <= maxMintPerTxPublic, "Mint less");
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

	//read metadata
	function _baseURI() internal view virtual returns (string memory) {
	return baseURI;
	}

	function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
	require(tokenId <= maxSupply);
	string memory currentBaseURI = _baseURI();
	return bytes(currentBaseURI).length > 0	? string(abi.encodePacked(currentBaseURI, tokenId.toString())) : "";
	}

    function updateMintCount(address minter, uint256 count) private {
    mintCountMap[minter] += count;
     }

    //price switch
	function setPrice(uint256 _newPrice) public onlyOwner {
	price = _newPrice;
	}

	//max switch
	function setMaxPerTxWhitelist(uint256 _newMaxMintAmount) public onlyOwner {
	maxMintPerTxWhitelist = _newMaxMintAmount;
	}

		//max switch
	function setMaxPerTxPublic(uint256 _newMaxMintAmount) public onlyOwner {
	maxMintPerTxPublic = _newMaxMintAmount;
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