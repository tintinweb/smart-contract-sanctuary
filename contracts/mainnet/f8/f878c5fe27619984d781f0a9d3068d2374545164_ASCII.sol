//       _    ____   ____ ___ ___  __     _______ ____  ____  _____ 
//      / \  / ___| / ___|_ _|_ _| \ \   / / ____|  _ \/ ___|| ____|
//     / _ \ \___ \| |    | | | |   \ \ / /|  _| | |_) \___ \|  _|  
//    / ___ \ ___) | |___ | | | |    \ V / | |___|  _ < ___) | |___ 
//   /_/   \_\____/ \____|___|___|    \_/  |_____|_| \_\____/|_____|
//  
//  Welcome 2 ASCIIVERSE - Your ticket into a unique metaverse based on ASCII
//  Genesis Project
//  Created by NFT OGs (Not PAK)
//  Community Driven - DAO
//  Scavenger Hunts - Prizes
//  Writing - Reading
//  Staking - Mining
//  PFP - Mint Pass
//  Gaming - P2E
//  Dreaming - WGMI
//  Just ASCII = 4A 55 53 54 20 41 53 43 49 49
//  Puzzle #1 - Find the secret message -> 38 38 38 20 74 6F 20 39 30 39

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './ERC721Enumerable.sol';
import './Ownable.sol';
import './Strings.sol';
import './ASCIIFunctions.sol';
import './Metadata.sol';

contract ASCII is ERC721Enumerable, Ownable, Functions, Metadata {
  using Strings for uint256;
  
  uint256 public constant totalAscii = 8910;
  uint256 public constant purchaseLimitPaid = 4;
  uint256 public purchaseLimitFree = 1;
  uint256 private price = 0.01 ether;

  bool public isMasterActive = false;

  string private _contractURI = '';
  string private _tokenBaseURI = '';
  string private _tokenRevealedBaseURI = '';

  mapping(address => uint256) private _freeMintTotal;
  mapping(address => uint256) private _paidMintTotal;

  address Address1 = 0xeDF821a5dB36B2267895E539927E824d5a86A87f; //team
  address Address2 = 0xEcc03efB7C0A7BD09A5cC7e954Ac42E8f949A0B5; //nl
  
  constructor(string memory name, string memory symbol) ERC721(name, symbol) {
  }

  function freeMintTotal(address owner) external view override returns (uint256){
    require(owner != address(0), 'Zero address');
    return _freeMintTotal[owner];
  }

  function paidMintTotal(address owner) external view override returns (uint256){
    require(owner != address(0), 'Zero address');
    return _paidMintTotal[owner];
  }
  
  function mintFreeAscii() external  {
    require(isMasterActive, 'Contract not active');
    require(totalSupply() < totalAscii, 'All tokens minted');
    require(_freeMintTotal[msg.sender] + 1 <= purchaseLimitFree,'Already maxed out');

    uint256 tokenId = totalSupply() + 1;
    _freeMintTotal[msg.sender] += 1;
    _safeMint(msg.sender, tokenId);
  }

  function mintPaidAscii(uint256 quantity) external payable  {
    require(isMasterActive, 'Contract not active');
    require(totalSupply() < totalAscii, 'All tokens minted');
    require(quantity <= purchaseLimitPaid, 'Mint less');
    require(_paidMintTotal[msg.sender] + quantity <= purchaseLimitPaid,'Already maxed out');
    require(totalSupply() + quantity <= totalAscii, 'Would exceed max supply');
    require(price * quantity == msg.value, 'ETH amount is not sufficient');

    for (uint256 i = 0; i < quantity; i++) {
    uint256 tokenId = totalSupply() + 1;
    _paidMintTotal[msg.sender] += 1;
    _safeMint(msg.sender, tokenId);
   }
  }

  function mintToWallet(address _0x) external onlyOwner  {
    require(isMasterActive, 'Contract not active');
    require(totalSupply() < totalAscii, 'All tokens minted');

    uint256 tokenId = totalSupply() + 1;
    _safeMint(_0x, tokenId);
  }

  function ContractSwitch(bool _isMasterActive) external override onlyOwner {
    isMasterActive = _isMasterActive;
  }
  
  function setMaxFree(uint256 _newMaxFree) public onlyOwner() {
     purchaseLimitFree = _newMaxFree;
  }
    
  function getmaxFree() public view returns (uint256){
     return purchaseLimitFree;
  }

  function withdraw() onlyOwner public {
    uint balance = address(this).balance;      
    payable(Address1).transfer(balance*95/100);      
    payable(Address2).transfer(balance*5/100);      
    payable(msg.sender).transfer(address(this).balance);
  }

  function setContractURI(string calldata URI) external override onlyOwner {
    _contractURI = URI;
  }

  function setMetadataURI(string calldata revealedBaseURI) external override onlyOwner {
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