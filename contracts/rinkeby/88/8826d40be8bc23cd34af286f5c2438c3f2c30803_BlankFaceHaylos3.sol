// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


abstract contract BLANKFACE {
  function ownerOf(uint256 tokenId) public virtual view returns (address);
  function tokenOfOwnerByIndex(address owner, uint256 index) public virtual view returns (uint256);
  function balanceOf(address owner) external virtual view returns (uint256 balance);
}

import './ERC721Enumerable.sol';
import './Ownable.sol';
import './Strings.sol';
import './Functions.sol';
import './Metadata.sol';

contract BlankFaceHaylos3 is ERC721Enumerable, Ownable, Functions, Metadata {
  using Strings for uint256;
  
  BLANKFACE private blankface;

  uint256 public constant COLLECTION1_MAX = 10000;
  uint256 public constant COLLECTION2_MAX = 10000;
  uint256 public constant COLLECTION3_MAX = 10000;
  uint256 public constant BUG = 1000;
  uint256 public constant NFT_MAX = COLLECTION1_MAX + COLLECTION2_MAX + COLLECTION3_MAX;
  uint256 public constant PURCHASE_LIMIT = 3;
  uint256 public constant PRICE = 0.01 ether;
  uint256 public constant mint3loop = 1;

  bool public isCollection1Active = false;
  bool public isCollection2Active = false;
  bool public isCollection3Active = false;
  bool public isMasterActive = false;
  
  string public message;

  uint256 public Collection1MaxMint = 1;
  uint256 public Collection2MaxMint = 1;
  uint256 public Collection3MaxMint = 1;

  /// @dev We will use these to be able to calculate remaining correctly.
  uint256 public totalCollection1Supply;
  uint256 public totalCollection2Supply;
  uint256 public totalCollection3Supply;

  mapping(address => bool) private _Collection1;
  mapping(address => uint256) private _Collection1Claimed;
  mapping(address => bool) private _Collection2;
  mapping(address => uint256) private _Collection2Claimed;
  mapping(address => bool) private _Collection3;
  mapping(address => uint256) private _Collection3Claimed;

  string private _contractURI = '';
  string private _tokenBaseURI = '';
  string private _tokenRevealedBaseURI = '';
  

  constructor(string memory name, string memory symbol, address dependentContractAddress) ERC721(name, symbol) {
 
    blankface = BLANKFACE(dependentContractAddress);
  }
      


//Collection1
  function addToCollection1(address[] calldata addresses) external override onlyOwner {
    for (uint256 i = 0; i < addresses.length; i++) {
      require(addresses[i] != address(0), "Can't add the null address");
      _Collection1[addresses[i]] = true;
      _Collection1Claimed[addresses[i]] > 0 ? _Collection1Claimed[addresses[i]] : 0;
    }
  }
  
  function onCollection1(address addr) external view override returns (bool) {
    return _Collection1[addr];
  }
  
  function removeFromCollection1(address[] calldata addresses) external override onlyOwner {
    for (uint256 i = 0; i < addresses.length; i++) {
      require(addresses[i] != address(0), "Can't add the null address");
      _Collection1[addresses[i]] = false;
    }
  }
  
  function Collection1ClaimedBy(address owner) external view override returns (uint256){
    require(owner != address(0), 'Zero address');
    return _Collection1Claimed[owner];
  }

//Collection2
  function addToCollection2(address[] calldata addresses) external override onlyOwner {
    for (uint256 i = 0; i < addresses.length; i++) {
      require(addresses[i] != address(0), "Can't add the null address");
      _Collection2[addresses[i]] = true;
      _Collection2Claimed[addresses[i]] > 0 ? _Collection2Claimed[addresses[i]] : 0;
    }
  }
  
  function onCollection2(address addr) external view override returns (bool) {
    return _Collection2[addr];
  }
  
  function removeFromCollection2(address[] calldata addresses) external override onlyOwner {
    for (uint256 i = 0; i < addresses.length; i++) {
      require(addresses[i] != address(0), "Can't add the null address");
      _Collection2[addresses[i]] = false;
    }
  }
  
  function Collection2ClaimedBy(address owner) external view override returns (uint256){
    require(owner != address(0), 'Zero address');
    return _Collection2Claimed[owner];
  }

//Collection3
  function addToCollection3(address[] calldata addresses) external override onlyOwner {
    for (uint256 i = 0; i < addresses.length; i++) {
      require(addresses[i] != address(0), "Can't add the null address");
      _Collection3[addresses[i]] = true;
      _Collection3Claimed[addresses[i]] > 0 ? _Collection3Claimed[addresses[i]] : 0;
    }
  }
  
  function onCollection3(address addr) external view override returns (bool) {
    return _Collection3[addr];
  }
  
  function removeFromCollection3(address[] calldata addresses) external override onlyOwner {
    for (uint256 i = 0; i < addresses.length; i++) {
      require(addresses[i] != address(0), "Can't add the null address");
      _Collection3[addresses[i]] = false;
    }
  }
  
  function Collection3ClaimedBy(address owner) external view override returns (uint256){
    require(owner != address(0), 'Zero address');
    return _Collection3Claimed[owner];
  }

  function mintCollection1(uint256 numberOfTokens) external override payable {
      
    uint balance = blankface.balanceOf(msg.sender);
    
    if (balance>0) {
    
    require(balance > 0, "Must hold at least BlankFace");
    
    
    
    require(isMasterActive, 'Contract is not active');
    require(isCollection1Active, 'Collection is not active');
    require(totalSupply() < NFT_MAX, 'All tokens have been minted');
    require(numberOfTokens <= Collection1MaxMint, 'Cannot purchase this many tokens');
    require(totalCollection1Supply + numberOfTokens <= COLLECTION1_MAX, 'Purchase would exceed max supply');
    require(_Collection1Claimed[msg.sender] + numberOfTokens <= Collection1MaxMint, 'Purchase exceeds max allowed');
    require(PRICE * numberOfTokens <= msg.value, 'ETH amount is not sufficient');

    for (uint256 i = 0; i < numberOfTokens; i++) {

      uint256 tokenId = totalCollection1Supply + 1;

      totalCollection1Supply += 1;
      _Collection1Claimed[msg.sender] += 1;
      _safeMint(msg.sender, tokenId);
    }
    
    }
    
    if (balance == 0) {

    require(isMasterActive, 'Contract is not active');
    require(isCollection1Active, 'Collection is not active');
    require(_Collection1[msg.sender], 'Must be on Haylos Whitelist');
    require(totalSupply() < NFT_MAX, 'All tokens have been minted');
    require(numberOfTokens <= Collection2MaxMint, 'Cannot purchase this many tokens');
    require(totalCollection1Supply + numberOfTokens <= COLLECTION1_MAX, 'Purchase would exceed max supply');
    require(_Collection1Claimed[msg.sender] + numberOfTokens <= Collection1MaxMint, 'Purchase exceeds max allowed');
    require(PRICE * numberOfTokens <= msg.value, 'ETH amount is not sufficient');

    for (uint256 i = 0; i < numberOfTokens; i++) {

      uint256 tokenId = totalCollection1Supply + 1;

      totalCollection1Supply += 1;
      _Collection1Claimed[msg.sender] += 1;
      _safeMint(msg.sender, tokenId);
    }
    
    }

  
  }
  
 function mintCollection2(uint256 numberOfTokens) external override payable {
      
    uint balance = blankface.balanceOf(msg.sender);
    
    if (balance>0) {
    
    require(balance > 0, "Must hold at least BlankFace");
    
    
    
    require(isMasterActive, 'Contract is not active');
    require(isCollection2Active, 'Collection is not active');
    require(totalSupply() < NFT_MAX, 'All tokens have been minted');
    require(numberOfTokens <= Collection2MaxMint, 'Cannot purchase this many tokens');
    require(totalCollection2Supply + numberOfTokens <= COLLECTION2_MAX, 'Purchase would exceed max supply');
    require(_Collection2Claimed[msg.sender] + numberOfTokens <= Collection2MaxMint, 'Purchase exceeds max allowed');
    require(PRICE * numberOfTokens <= msg.value, 'ETH amount is not sufficient');

    for (uint256 i = 0; i < numberOfTokens; i++) {

      uint256 tokenId = COLLECTION1_MAX + totalCollection2Supply + 1;

      totalCollection2Supply += 1;
      _Collection2Claimed[msg.sender] += 1;
      _safeMint(msg.sender, tokenId);
    }
    
    }
    
    if (balance == 0) {

    require(isMasterActive, 'Contract is not active');
    require(isCollection2Active, 'Collection is not active');
    require(_Collection2[msg.sender], 'Must be on Haylos Whitelist');
    require(totalSupply() < NFT_MAX, 'All tokens have been minted');
    require(numberOfTokens <= Collection2MaxMint, 'Cannot purchase this many tokens');
    require(totalCollection2Supply + numberOfTokens <= COLLECTION2_MAX, 'Purchase would exceed max supply');
    require(_Collection2Claimed[msg.sender] + numberOfTokens <= Collection2MaxMint, 'Purchase exceeds max allowed');
    require(PRICE * numberOfTokens <= msg.value, 'ETH amount is not sufficient');

    for (uint256 i = 0; i < numberOfTokens; i++) {

      uint256 tokenId = COLLECTION1_MAX + totalCollection2Supply + 1;

      totalCollection2Supply += 1;
      _Collection2Claimed[msg.sender] += 1;
      _safeMint(msg.sender, tokenId);
    }
    
    }

  
  }
  
  function mintCollection3(uint256 numberOfTokens) external override payable {
      
    uint balance = blankface.balanceOf(msg.sender);
    
    if (balance>0) {
    
    require(balance > 0, "Must hold at least BlankFace");
    
    
    
    require(isMasterActive, 'Contract is not active');
    require(isCollection3Active, 'Collection is not active');
    require(totalSupply() < NFT_MAX, 'All tokens have been minted');
    require(numberOfTokens <= Collection3MaxMint, 'Cannot purchase this many tokens');
    require(totalCollection3Supply + numberOfTokens <= COLLECTION3_MAX, 'Purchase would exceed max supply');
    require(_Collection3Claimed[msg.sender] + numberOfTokens <= Collection3MaxMint, 'Purchase exceeds max allowed');
    require(PRICE * numberOfTokens <= msg.value, 'ETH amount is not sufficient');

    for (uint256 i = 0; i < numberOfTokens; i++) {

      uint256 tokenId = BUG + COLLECTION1_MAX + COLLECTION2_MAX + totalCollection3Supply + 1;

      totalCollection3Supply += 1;
      _Collection3Claimed[msg.sender] += 1;
      _safeMint(msg.sender, tokenId);
    }
    
    }
    
    if (balance == 0) {

    require(isMasterActive, 'Contract is not active');
    require(isCollection3Active, 'Collection is not active');
    require(_Collection3[msg.sender], 'Must be on Haylos Whitelist');
    require(totalSupply() < NFT_MAX, 'All tokens have been minted');
    require(numberOfTokens <= Collection3MaxMint, 'Cannot purchase this many tokens');
    require(totalCollection3Supply + numberOfTokens <= COLLECTION3_MAX, 'Purchase would exceed max supply');
    require(_Collection3Claimed[msg.sender] + numberOfTokens <= Collection3MaxMint, 'Purchase exceeds max allowed');
    require(PRICE * numberOfTokens <= msg.value, 'ETH amount is not sufficient');

    for (uint256 i = 0; i < numberOfTokens; i++) {

      uint256 tokenId = BUG + COLLECTION1_MAX + COLLECTION2_MAX + totalCollection3Supply + 1;

      totalCollection3Supply += 1;
      _Collection3Claimed[msg.sender] += 1;
      _safeMint(msg.sender, tokenId);
    }
    
    }

  
  }
  


  function MasterActive(bool _isMasterActive) external override onlyOwner {
    isMasterActive = _isMasterActive;
  }
  


  function Collection1Active(bool _isCollection1Active) external override onlyOwner {
    isCollection1Active = _isCollection1Active;
  }
  
  function Collection2Active(bool _isCollection2Active) external override onlyOwner {
    isCollection2Active = _isCollection2Active;
  }
  
  function Collection3Active(bool _isCollection3Active) external override onlyOwner {
    isCollection3Active = _isCollection3Active;
  }

  function setMessage(string calldata messageString) external override onlyOwner {
    message = messageString;
  }
  
  function withdraw() external override onlyOwner {
    uint256 balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }

  function setContractURI(string calldata URI) external override onlyOwner {
    _contractURI = URI;
  }

  function setBaseURI(string calldata URI) external override onlyOwner {
    _tokenBaseURI = URI;
  }

  function setRevealedBaseURI(string calldata revealedBaseURI) external override onlyOwner {
    _tokenRevealedBaseURI = revealedBaseURI;
  }

  function contractURI() public view override returns (string memory) {
    return _contractURI;
  }

  function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
    require(_exists(tokenId), 'Token does not exist');

    /// @dev Convert string to bytes so we can check if it's empty or not.
    string memory revealedBaseURI = _tokenRevealedBaseURI;
    return bytes(revealedBaseURI).length > 0 ?
      string(abi.encodePacked(revealedBaseURI, tokenId.toString())) :
      _tokenBaseURI;
  }
}