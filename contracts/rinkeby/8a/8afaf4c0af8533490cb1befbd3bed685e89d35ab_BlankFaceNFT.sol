// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './ERC721Enumerable.sol';
import './Ownable.sol';
import './Strings.sol';
import './Functions.sol';
import './Metadata.sol';

contract BlankFaceNFT is ERC721Enumerable, Ownable, Functions, Metadata {
  using Strings for uint256;

  uint256 public constant RESERVE = 100;
  uint256 public constant PUBLIC = 9900;
  uint256 public constant NFT_MAX = RESERVE + PUBLIC;
  uint256 public constant PURCHASE_LIMIT = 5;
  uint256 public constant PRICE = 0.0888 ether;

  bool public isTier1Active = false;
  bool public isTier2Active = false;
  bool public isTier3Active = false;
  bool public isTier4Active = false;
  bool public isTier5Active = false;
  bool public isTier6Active = false;

  bool public isMasterActive = false;
  bool public isPublicActive = false;
  
  string public message;

  uint256 public Tier1MaxMint = 1;
  uint256 public Tier2MaxMint = 2;
  uint256 public Tier3MaxMint = 3;
  uint256 public Tier4MaxMint = 4;
  uint256 public Tier5MaxMint = 5;
  uint256 public Tier6MaxMint = 6;

  /// @dev We will use these to be able to calculate remaining correctly.
  uint256 public totalReserveSupply;
  uint256 public totalPublicSupply;

  mapping(address => bool) private _Tier1;
  mapping(address => uint256) private _Tier1Claimed;
  mapping(address => bool) private _Tier2;
  mapping(address => uint256) private _Tier2Claimed;
  mapping(address => bool) private _Tier3;
  mapping(address => uint256) private _Tier3Claimed;
  mapping(address => bool) private _Tier4;
  mapping(address => uint256) private _Tier4Claimed;
  mapping(address => bool) private _Tier5;
  mapping(address => uint256) private _Tier5Claimed;
  mapping(address => bool) private _Tier6;
  mapping(address => uint256) private _Tier6Claimed;

  string private _contractURI = '';
  string private _tokenBaseURI = '';
  string private _tokenRevealedBaseURI = '';

  constructor(string memory name, string memory symbol) ERC721(name, symbol) {}


//tier1
  function addToTier1(address[] calldata addresses) external override onlyOwner {
    for (uint256 i = 0; i < addresses.length; i++) {
      require(addresses[i] != address(0), "Can't add the null address");
      _Tier1[addresses[i]] = true;
      _Tier1Claimed[addresses[i]] > 0 ? _Tier1Claimed[addresses[i]] : 0;
    }
  }
  
  function onTier1(address addr) external view override returns (bool) {
    return _Tier1[addr];
  }
  
  function removeFromTier1(address[] calldata addresses) external override onlyOwner {
    for (uint256 i = 0; i < addresses.length; i++) {
      require(addresses[i] != address(0), "Can't add the null address");
      _Tier1[addresses[i]] = false;
    }
  }
  
  function Tier1ClaimedBy(address owner) external view override returns (uint256){
    require(owner != address(0), 'Zero address');
    return _Tier1Claimed[owner];
  }


//tier2
  function addToTier2(address[] calldata addresses) external override onlyOwner {
    for (uint256 i = 0; i < addresses.length; i++) {
      require(addresses[i] != address(0), "Can't add the null address");
      _Tier2[addresses[i]] = true;
      _Tier2Claimed[addresses[i]] > 0 ? _Tier2Claimed[addresses[i]] : 0;
    }
  }
  
  function onTier2(address addr) external view override returns (bool) {
    return _Tier2[addr];
  }
  
  function removeFromTier2(address[] calldata addresses) external override onlyOwner {
    for (uint256 i = 0; i < addresses.length; i++) {
      require(addresses[i] != address(0), "Can't add the null address");
      _Tier2[addresses[i]] = false;
    }
  }

  function Tier2ClaimedBy(address owner) external view override returns (uint256){
    require(owner != address(0), 'Zero address');
    return _Tier2Claimed[owner];
  }


//tier3
  function addToTier3(address[] calldata addresses) external override onlyOwner {
    for (uint256 i = 0; i < addresses.length; i++) {
      require(addresses[i] != address(0), "Can't add the null address");
      _Tier3[addresses[i]] = true;
      _Tier3Claimed[addresses[i]] > 0 ? _Tier3Claimed[addresses[i]] : 0;
    }
  }
  
  function onTier3(address addr) external view override returns (bool) {
    return _Tier3[addr];
  }
  
  function removeFromTier3(address[] calldata addresses) external override onlyOwner {
    for (uint256 i = 0; i < addresses.length; i++) {
      require(addresses[i] != address(0), "Can't add the null address");
      _Tier3[addresses[i]] = false;
    }
  }
  
  function Tier3ClaimedBy(address owner) external view override returns (uint256){
    require(owner != address(0), 'Zero address');
    return _Tier3Claimed[owner];
  }


//tier4
  function addToTier4(address[] calldata addresses) external override onlyOwner {
    for (uint256 i = 0; i < addresses.length; i++) {
      require(addresses[i] != address(0), "Can't add the null address");
      _Tier4[addresses[i]] = true;
      _Tier4Claimed[addresses[i]] > 0 ? _Tier4Claimed[addresses[i]] : 0;
    }
  }
  
  function onTier4(address addr) external view override returns (bool) {
    return _Tier4[addr];
  }
  
  function removeFromTier4(address[] calldata addresses) external override onlyOwner {
    for (uint256 i = 0; i < addresses.length; i++) {
      require(addresses[i] != address(0), "Can't add the null address");
      _Tier4[addresses[i]] = false;
    }
  }
  
 function Tier4ClaimedBy(address owner) external view override returns (uint256){
    require(owner != address(0), 'Zero address');
    return _Tier4Claimed[owner];
  }


//tier5
 function addToTier5(address[] calldata addresses) external override onlyOwner {
    for (uint256 i = 0; i < addresses.length; i++) {
      require(addresses[i] != address(0), "Can't add the null address");
      _Tier5[addresses[i]] = true;
      _Tier5Claimed[addresses[i]] > 0 ? _Tier5Claimed[addresses[i]] : 0;
    }
  }
  
  function onTier5(address addr) external view override returns (bool) {
    return _Tier5[addr];
  }
  
  function removeFromTier5(address[] calldata addresses) external override onlyOwner {
    for (uint256 i = 0; i < addresses.length; i++) {
      require(addresses[i] != address(0), "Can't add the null address");
      _Tier5[addresses[i]] = false;
    }
  }
  
  
 function Tier5ClaimedBy(address owner) external view override returns (uint256){
    require(owner != address(0), 'Zero address');

    return _Tier5Claimed[owner];
  }
  
//Tier6
 function addToTier6(address[] calldata addresses) external override onlyOwner {
    for (uint256 i = 0; i < addresses.length; i++) {
      require(addresses[i] != address(0), "Can't add the null address");
      _Tier6[addresses[i]] = true;
      _Tier6Claimed[addresses[i]] > 0 ? _Tier4Claimed[addresses[i]] : 0;
    }
  }
  
  function onTier6(address addr) external view override returns (bool) {
    return _Tier6[addr];
  }
  
  function removeFromTier6(address[] calldata addresses) external override onlyOwner {
    for (uint256 i = 0; i < addresses.length; i++) {
      require(addresses[i] != address(0), "Can't add the null address");
      _Tier6[addresses[i]] = false;
    }
  }
  
 function Tier6ClaimedBy(address owner) external view override returns (uint256){
    require(owner != address(0), 'Zero address');

    return _Tier6Claimed[owner];
  }


  function mintTier1(uint256 numberOfTokens) external override payable {


    require(isMasterActive, 'Contract is not active');
    require(isTier1Active, 'Tier is not active');
    require(_Tier1[msg.sender]);
    require(totalSupply() < NFT_MAX, 'All tokens have been minted');
    require(numberOfTokens <= Tier1MaxMint, 'Cannot purchase this many tokens');
    require(totalPublicSupply + numberOfTokens <= PUBLIC, 'Purchase would exceed max supply');
    require(_Tier1Claimed[msg.sender] + numberOfTokens <= Tier1MaxMint, 'Purchase exceeds max allowed');
    require(PRICE * numberOfTokens <= msg.value, 'ETH amount is not sufficient');

    for (uint256 i = 0; i < numberOfTokens; i++) {

      uint256 tokenId = RESERVE + totalPublicSupply + 1;

      totalPublicSupply += 1;
      _Tier1Claimed[msg.sender] += 1;
      _safeMint(msg.sender, tokenId);
    }

  
  }
  
    function mintTier2(uint256 numberOfTokens) external override payable {


    require(isMasterActive, 'Contract is not active');
    require(isTier2Active, 'Tier is not active');
    require(_Tier2[msg.sender]);
    require(totalSupply() < NFT_MAX, 'All tokens have been minted');
    require(numberOfTokens <= Tier2MaxMint, 'Cannot purchase this many tokens');
    require(totalPublicSupply + numberOfTokens <= PUBLIC, 'Purchase would exceed max supply');
    require(_Tier2Claimed[msg.sender] + numberOfTokens <= Tier2MaxMint, 'Purchase exceeds max allowed');
    require(PRICE * numberOfTokens <= msg.value, 'ETH amount is not sufficient');

    for (uint256 i = 0; i < numberOfTokens; i++) {

      uint256 tokenId = RESERVE + totalPublicSupply + 1;

      totalPublicSupply += 1;
      _Tier2Claimed[msg.sender] += 1;
      _safeMint(msg.sender, tokenId);
    }

  
  }
  
function mintTier3(uint256 numberOfTokens) external override payable {


    require(isMasterActive, 'Contract is not active');
    require(isTier3Active, 'Tier is not active');
    require(_Tier3[msg.sender]);
    require(totalSupply() < NFT_MAX, 'All tokens have been minted');
    require(numberOfTokens <= Tier3MaxMint, 'Cannot purchase this many tokens');
    require(totalPublicSupply + numberOfTokens <= PUBLIC, 'Purchase would exceed max supply');
    require(_Tier3Claimed[msg.sender] + numberOfTokens <= Tier3MaxMint, 'Purchase exceeds max allowed');
    require(PRICE * numberOfTokens <= msg.value, 'ETH amount is not sufficient');

    for (uint256 i = 0; i < numberOfTokens; i++) {

      uint256 tokenId = RESERVE + totalPublicSupply + 1;

      totalPublicSupply += 1;
      _Tier3Claimed[msg.sender] += 1;
      _safeMint(msg.sender, tokenId);
    }

  
  }
  
function mintTier4(uint256 numberOfTokens) external override payable {


    require(isMasterActive, 'Contract is not active');
    require(isTier4Active, 'Tier is not active');
    require(_Tier4[msg.sender]);
    require(totalSupply() < NFT_MAX, 'All tokens have been minted');
    require(numberOfTokens <= Tier4MaxMint, 'Cannot purchase this many tokens');
    require(totalPublicSupply + numberOfTokens <= PUBLIC, 'Purchase would exceed max supply');
    require(_Tier4Claimed[msg.sender] + numberOfTokens <= Tier4MaxMint, 'Purchase exceeds max allowed');
    require(PRICE * numberOfTokens <= msg.value, 'ETH amount is not sufficient');

    for (uint256 i = 0; i < numberOfTokens; i++) {

      uint256 tokenId = RESERVE + totalPublicSupply + 1;

      totalPublicSupply += 1;
      _Tier4Claimed[msg.sender] += 1;
      _safeMint(msg.sender, tokenId);
    }

  
  }
  
  
function mintTier5(uint256 numberOfTokens) external override payable {


    require(isMasterActive, 'Contract is not active');
    require(isTier5Active, 'Tier is not active');
    require(_Tier5[msg.sender]);
    require(totalSupply() < NFT_MAX, 'All tokens have been minted');
    require(numberOfTokens <= Tier5MaxMint, 'Cannot purchase this many tokens');
    require(totalPublicSupply + numberOfTokens <= PUBLIC, 'Purchase would exceed max supply');
    require(_Tier5Claimed[msg.sender] + numberOfTokens <= Tier5MaxMint, 'Purchase exceeds max allowed');
    require(PRICE * numberOfTokens <= msg.value, 'ETH amount is not sufficient');

    for (uint256 i = 0; i < numberOfTokens; i++) {

      uint256 tokenId = RESERVE + totalPublicSupply + 1;

      totalPublicSupply += 1;
      _Tier5Claimed[msg.sender] += 1;
      _safeMint(msg.sender, tokenId);
    }

  
  }
  
function mintTier6(uint256 numberOfTokens) external override payable {


    require(isMasterActive, 'Contract is not active');
    require(isTier6Active, 'Tier is not active');
    require(_Tier6[msg.sender]);
    require(totalSupply() < NFT_MAX, 'All tokens have been minted');
    require(numberOfTokens <= Tier6MaxMint, 'Cannot purchase this many tokens');
    require(totalPublicSupply + numberOfTokens <= PUBLIC, 'Purchase would exceed max supply');
    require(_Tier6Claimed[msg.sender] + numberOfTokens <= Tier6MaxMint, 'Purchase exceeds max allowed');
    require(PRICE * numberOfTokens <= msg.value, 'ETH amount is not sufficient');

    for (uint256 i = 0; i < numberOfTokens; i++) {

      uint256 tokenId = RESERVE + totalPublicSupply + 1;

      totalPublicSupply += 1;
      _Tier6Claimed[msg.sender] += 1;
      _safeMint(msg.sender, tokenId);
    }

  
  }
  
function mintPublic(uint256 numberOfTokens) external override payable {

    require(isMasterActive, 'Contract is not active');
    require(isPublicActive, 'Public is not active');
    
    require(totalSupply() < NFT_MAX, 'All tokens have been minted');
    require(numberOfTokens <= PURCHASE_LIMIT, 'Cannot purchase this many tokens');
    require(totalPublicSupply + numberOfTokens <= PUBLIC, 'Purchase would exceed max supply');
    require(PRICE * numberOfTokens <= msg.value, 'ETH amount is not sufficient');

    for (uint256 i = 0; i < numberOfTokens; i++) {

      uint256 tokenId = RESERVE + totalPublicSupply + 1;

      totalPublicSupply += 1;
      _safeMint(msg.sender, tokenId);
    }

  }

  function reserve(address[] calldata to) external override onlyOwner {
    require(totalSupply() < NFT_MAX, 'All tokens have been minted');
    require(totalReserveSupply + to.length <= RESERVE, 'Not enough tokens left to reserve');

    for(uint256 i = 0; i < to.length; i++) {
      uint256 tokenId = totalReserveSupply + 1;

      totalReserveSupply += 1;
      _safeMint(to[i], tokenId);
    }
  }

  function MasterActive(bool _isMasterActive) external override onlyOwner {
    isMasterActive = _isMasterActive;
  }
  
  function PublicActive(bool _isPublicActive) external override onlyOwner {
    isPublicActive = _isPublicActive;
  }

  function Tier1Active(bool _isTier1Active) external override onlyOwner {
    isTier1Active = _isTier1Active;
  }
  
  function Tier2Active(bool _isTier2Active) external override onlyOwner {
    isTier2Active = _isTier2Active;
  }
  
  function Tier3Active(bool _isTier3Active) external override onlyOwner {
    isTier3Active = _isTier3Active;
  }

  function Tier4Active(bool _isTier4Active) external override onlyOwner {
    isTier4Active = _isTier4Active;
  }

  function Tier5Active(bool _isTier5Active) external override onlyOwner {
    isTier5Active = _isTier5Active;
  }

  function Tier6Active(bool _isTier6Active) external override onlyOwner {
    isTier6Active = _isTier6Active;
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