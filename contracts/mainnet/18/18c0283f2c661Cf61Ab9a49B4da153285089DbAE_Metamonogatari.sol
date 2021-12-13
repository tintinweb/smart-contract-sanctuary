// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './ERC721Enumerable.sol';
import './Ownable.sol';
import './Strings.sol';
import './Functions.sol';
import './Metadata.sol';


contract Metamonogatari is ERC721Enumerable, Ownable, Functions, Metadata {
  using Strings for uint256;
  

  uint256 public constant RESERVE = 20;
  uint256 public constant PUBLIC = 1980;
  uint256 public constant WL = 1500;
  uint256 public constant NFT_MAX = RESERVE + PUBLIC;
  uint256 public constant PURCHASE_LIMIT = 2;
  uint256 public WhitelistMaxMint = 1;
  uint256 public constant PRICE = 0.04 ether;

  bool public isWhitelistActive = false;
  bool public isMasterActive = false;
  bool public isPublicActive = false;
  
  string public message;

  

  /// @dev We will use these to be able to calculate remaining correctly.
  uint256 public totalReserveSupply;
  uint256 public totalPublicSupply;
  
  mapping(address => bool) private _Whitelist;
  mapping(address => uint256) private _WhitelistClaimed;
  

  string private _contractURI = '';
  string private _tokenBaseURI = '';
  string private _tokenRevealedBaseURI = '';

  constructor() public ERC721("Metamonogatari", "MMG") {}

//Whitelist
  function addToWhitelist(address[] calldata addresses) external override onlyOwner {
    for (uint256 i = 0; i < addresses.length; i++) {
      require(addresses[i] != address(0), "Can't add the null address");
      _Whitelist[addresses[i]] = true;
      _WhitelistClaimed[addresses[i]] > 0 ? _WhitelistClaimed[addresses[i]] : 0;
    }
  }
  
  function onWhitelist(address addr) external view override returns (bool) {
    return _Whitelist[addr];
  }
  
  function removeFromWhitelist(address[] calldata addresses) external override onlyOwner {
    for (uint256 i = 0; i < addresses.length; i++) {
      require(addresses[i] != address(0), "Can't add the null address");
      _Whitelist[addresses[i]] = false;
    }
  }
  
  function WhitelistClaimedBy(address owner) external view override returns (uint256){
    require(owner != address(0), 'Zero address');
    return _WhitelistClaimed[owner];
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
function mintWhitelist(uint256 numberOfTokens) external override payable {


    require(isMasterActive, 'Contract is not active');
    require(isWhitelistActive, 'Whitelist is not active');
    require(_Whitelist[msg.sender]);
    require(totalSupply() < NFT_MAX, 'All tokens have been minted');
    require(numberOfTokens <= WhitelistMaxMint, 'Cannot purchase this many tokens');
    require(totalPublicSupply + numberOfTokens <= WL, 'Purchase would exceed max supply');
    require(totalPublicSupply + numberOfTokens <= PUBLIC, 'Purchase would exceed max supply');
    require(_WhitelistClaimed[msg.sender] + numberOfTokens <= WhitelistMaxMint, 'Purchase exceeds max allowed');
    require(PRICE * numberOfTokens <= msg.value, 'ETH amount is not sufficient');

    for (uint256 i = 0; i < numberOfTokens; i++) {

      uint256 tokenId = RESERVE + totalPublicSupply + 1;

      totalPublicSupply += 1;
      _WhitelistClaimed[msg.sender] += 1;
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
  
  function WhitelistActive(bool _isWhitelistActive) external override onlyOwner {
    isWhitelistActive = _isWhitelistActive;
  }
  function PublicActive(bool _isPublicActive) external override onlyOwner {
    isPublicActive = _isPublicActive;
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

    string memory revealedBaseURI = _tokenRevealedBaseURI;
    return bytes(revealedBaseURI).length > 0 ?
      string(abi.encodePacked(revealedBaseURI, tokenId.toString())) :
      _tokenBaseURI;
  }
}