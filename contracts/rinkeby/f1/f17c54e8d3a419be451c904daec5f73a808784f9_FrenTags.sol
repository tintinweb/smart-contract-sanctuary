// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import './ERC721Enumerable.sol';
import './Ownable.sol';
import './Strings.sol';
import './FrenFunctions.sol';
import './Metadata.sol';

contract FrenTags is ERC721Enumerable, Ownable, Functions, Metadata {
    
    using Strings for uint256;
  
    uint256 public constant NFT_MAX = 101;
    uint256 public constant PURCHASE_LIMIT = 1;
    uint256 public constant PURCHASE_LIMIT_PER_WALLET = 10;
    uint256 private price = 0.5 ether;

    bool public isMasterActive = false;

    string private _contractURI = '';
    string private _tokenBaseURI = '';
    string private _tokenRevealedBaseURI = '';
  
    constructor(string memory name, string memory symbol) ERC721(name, symbol) {
    }
  
    function mint(uint256 numberOfTokens) external payable {

    require(isMasterActive, 'Contract is not active');
    require(totalSupply() < NFT_MAX, 'All tokens have been minted');
    require(numberOfTokens > 0, 'You must mint more than 1 token');
    require(balanceOf(msg.sender) <= PURCHASE_LIMIT_PER_WALLET,'You can only mint 2 tokens');
    require(numberOfTokens <= PURCHASE_LIMIT, 'Cannot purchase this many tokens');
    require(totalSupply() + numberOfTokens <= NFT_MAX, 'Purchase would exceed max supply');
    require(price * numberOfTokens <= msg.value, 'ETH amount is not sufficient');

    for (uint256 i = 0; i < numberOfTokens; i++) {

    if(totalSupply() == 0){
        
           _safeMint(msg.sender, 0);
        
    }
    
    
      if(totalSupply() > 0){
        
  uint256 tokenId = totalSupply() + 1;

      _safeMint(msg.sender, tokenId);
        
    }

      
    }
    
    }
    
    //reserve
    function reserve(address[] calldata to) external  onlyOwner {
    require(totalSupply() < NFT_MAX, 'All tokens have been minted');

    for(uint256 i = 0; i < to.length; i++) {
        
        
    if(totalSupply() == 0){
        
           _safeMint(msg.sender, 0);
        
    }
    
    
    if(totalSupply() > 0){
        
        
      uint256 tokenId = totalSupply() + 1;

      _safeMint(to[i], tokenId);
    }

       }
     }

    function MasterActive(bool _isMasterActive) external override onlyOwner {
    isMasterActive = _isMasterActive;
    }
  
    function setPrice(uint256 _newPrice) public onlyOwner() {
        price = _newPrice;
    }
    
    function getPrice() public view returns (uint256){
        return price;
    }
    
    address Address1 = 0xC824bb8d841fDD2aBAF9e3934e86CD670EA767EA; //update
    address Address2 = 0xEcc03efB7C0A7BD09A5cC7e954Ac42E8f949A0B5; //update
  
    function withdraw() onlyOwner public {
        uint balance = address(this).balance;
        payable(Address1).transfer(balance*92/100);
        payable(Address2).transfer(balance*8/100);
        payable(msg.sender).transfer(address(this).balance);
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