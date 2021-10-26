// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract ADAMBOMBSQUAD {
  function ownerOf(uint256 tokenId) public virtual view returns (address);
  function tokenOfOwnerByIndex(address owner, uint256 index) public virtual view returns (uint256);
  function balanceOf(address owner) external virtual view returns (uint256 balance);
}

import './ERC721Enumerable.sol';
import './Ownable.sol';
import './Strings.sol';
import './DiamondFunctions.sol';
import './Metadata.sol';

contract DiamondCryptoDunks is ERC721Enumerable, Ownable, Functions, Metadata {
  using Strings for uint256;
  
  ADAMBOMBSQUAD private adambombsquad;
  
  //globallimits
  uint256 public constant AIRDROP = 447;
  uint256 public constant NFT_MAX = 15000;
 
  //limitsperwallet
  uint256 public constant PURCHASE_LIMIT = 10;
  uint256 public constant ABS_MAX = 10;
  uint256 public constant FIRESTARTER1 = 10;
  uint256 public constant FIRESTARTER2 = 20;

  //pricepertype
  uint256 private pricemain = 0.08 ether;
  uint256 private pricewhitelist = 0.07 ether;
 
  //switches
  bool public isMasterActive = false;
  
  bool public isPresaleActive = false;
  bool public isWhitelistActive = false;
  bool public isBombSquadActive = false;
  bool public isFirestarterActive = false;
  bool public isPublicActive = false;
 
  //supplycounters
  uint256 public totalReserveSupply;
  uint256 public totalAirdropSupply;
  uint256 public totalPresaleSupply;
  uint256 public totalBombSquadSupply;
  uint256 public totalWhitelistSupply;
  uint256 public totalFirestarter1Supply;
  uint256 public totalFirestarter2Supply;
  uint256 public totalFirestarter3Supply;
  uint256 public totalFirestarter4Supply;
  uint256 public totalFirestarter5Supply;
  uint256 public totalPublicSupply;

  //lists
  mapping(address => bool) private _Presale;
  mapping(address => uint256) private _PresaleClaimed;
  mapping(address => bool) private _Whitelist;
  mapping(address => uint256) private _WhitelistClaimed;
  mapping(address => bool) private _Firestarter1;
  mapping(address => uint256) private _Firestarter1Claimed;
  mapping(address => bool) private _Firestarter2;
  mapping(address => uint256) private _Firestarter2Claimed;
  
  //metadata
  string private _contractURI = '';
  string private _tokenBaseURI = '';
  string private _tokenRevealedBaseURI = '';
  
  //constructor
  constructor(
      string memory name, 
      string memory symbol, 
      address adambombsquadContractAddress)
      
        ERC721(name, symbol) {
 
             adambombsquad = ADAMBOMBSQUAD(adambombsquadContractAddress);
        }
 
    //presale
  function addToPresale(address[] calldata addresses) external override onlyOwner {
    for (uint256 i = 0; i < addresses.length; i++) {
      require(addresses[i] != address(0), "Can't add the null address");
      _Presale[addresses[i]] = true;
      _PresaleClaimed[addresses[i]] > 0 ? _PresaleClaimed[addresses[i]] : 0;
    }
  }
  
  function onPresale(address addr) external view override returns (bool) {
    return _Presale[addr];
  }
  
  function removeFromPresale(address[] calldata addresses) external override onlyOwner {
    for (uint256 i = 0; i < addresses.length; i++) {
      require(addresses[i] != address(0), "Can't add the null address");
      _Presale[addresses[i]] = false;
    }
  }
  
  function PresaleClaimedBy(address owner) external view override returns (uint256){
    require(owner != address(0), 'Zero address');
    return _PresaleClaimed[owner];
  }          
        
   //whitelist
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
  
    //firestarter tier 1
  function addToFirestarter1(address[] calldata addresses) external override onlyOwner {
    for (uint256 i = 0; i < addresses.length; i++) {
      require(addresses[i] != address(0), "Can't add the null address");
      _Firestarter1[addresses[i]] = true;
      _Firestarter1Claimed[addresses[i]] > 0 ? _Firestarter1Claimed[addresses[i]] : 0;
    }
  }
  
  function onFirestarter1(address addr) external view override returns (bool) {
    return _Firestarter1[addr];
  }
  
  function removeFromFirestarter1(address[] calldata addresses) external override onlyOwner {
    for (uint256 i = 0; i < addresses.length; i++) {
      require(addresses[i] != address(0), "Can't add the null address");
      _Firestarter1[addresses[i]] = false;
    }
  }
  
  function Firestarter1ClaimedBy(address owner) external view override returns (uint256){
    require(owner != address(0), 'Zero address');
    return _Firestarter1Claimed[owner];
  }  
  
     //firestarter tier 2
  function addToFirestarter2(address[] calldata addresses) external override onlyOwner {
    for (uint256 i = 0; i < addresses.length; i++) {
      require(addresses[i] != address(0), "Can't add the null address");
      _Firestarter2[addresses[i]] = true;
      _Firestarter2Claimed[addresses[i]] > 0 ? _Firestarter2Claimed[addresses[i]] : 0;
    }
  }
  
  function onFirestarter2(address addr) external view override returns (bool) {
    return _Firestarter2[addr];
  }
  
  function removeFromFirestarter2(address[] calldata addresses) external override onlyOwner {
    for (uint256 i = 0; i < addresses.length; i++) {
      require(addresses[i] != address(0), "Can't add the null address");
      _Firestarter2[addresses[i]] = false;
    }
  }
  
  function Firestarter2ClaimedBy(address owner) external view override returns (uint256){
    require(owner != address(0), 'Zero address');
    return _Firestarter2Claimed[owner];
  } 
  
  
   //whitelist
  function mintwhitelist(uint256 numberOfTokens) external payable {

    //check switches
    require(isMasterActive, 'Contract is not active');
    require(isWhitelistActive, 'This portion of minting is not active');
    require(_Whitelist[msg.sender]);
    
    //supply check
    require(totalSupply() < NFT_MAX, 'All tokens have been minted');
    require(numberOfTokens > 0, 'You must mint more than 1 token');
          if(numberOfTokens >= 5) {
    require(totalSupply() + numberOfTokens + 1 <= NFT_MAX, 'Purchase would exceed max supply');
         }
           if(numberOfTokens < 5) {
    require(totalSupply() + numberOfTokens <= NFT_MAX, 'Purchase would exceed max supply');
         }
    require(balanceOf(msg.sender) <= PURCHASE_LIMIT,'You hit the max per wallet');


    require(totalSupply() + numberOfTokens <= NFT_MAX, 'Purchase would exceed max supply');

   
    //calculate prices
    require(pricewhitelist * numberOfTokens <= msg.value, 'ETH amount is not sufficient');

    //mint!
    
        if(numberOfTokens >= 5) {
    
    for (uint256 i = 0; i < numberOfTokens + 1; i++) {

      uint256 tokenId = totalSupply() + 1;
        totalWhitelistSupply += 1;

      _safeMint(msg.sender, tokenId);
    }

    }
    
     if(numberOfTokens < 5) {
    
    for (uint256 i = 0; i < numberOfTokens; i++) {

      uint256 tokenId = totalSupply() + 1;
        totalWhitelistSupply += 1;

      _safeMint(msg.sender, tokenId);
    }
    
    }

    }
  

  //presale
  function mintpresale(uint256 numberOfTokens) external payable {

    //check switches
    require(isMasterActive, 'Contract is not active');
    require(isPresaleActive, 'This portion of minting is not active');
    require(_Presale[msg.sender]);
    
    //supply check
    require(totalSupply() < NFT_MAX, 'All tokens have been minted');
    require(numberOfTokens > 0, 'You must mint more than 1 token');
    require(numberOfTokens <= PURCHASE_LIMIT, 'Cannot purchase this many tokens');
      
        if(numberOfTokens >= 5) {
    require(totalSupply() + numberOfTokens + 1 <= NFT_MAX, 'Purchase would exceed max supply');
         }
           if(numberOfTokens < 5) {
    require(totalSupply() + numberOfTokens <= NFT_MAX, 'Purchase would exceed max supply');
         }

    require(balanceOf(msg.sender) <= PURCHASE_LIMIT,'You hit the max per wallet');
   
    //calculate prices
    require(pricemain * numberOfTokens <= msg.value, 'ETH amount is not sufficient');

    //mint!
    
    if(numberOfTokens >= 5) {
    
    for (uint256 i = 0; i < numberOfTokens + 1; i++) {

      uint256 tokenId = totalSupply() + 1;
        totalPresaleSupply += 1;

      _safeMint(msg.sender, tokenId);
    }

    }
    
     if(numberOfTokens < 5) {
    
    for (uint256 i = 0; i < numberOfTokens; i++) {

      uint256 tokenId = totalSupply() + 1;
        totalPresaleSupply += 1;

      _safeMint(msg.sender, tokenId);
    }
    
    
    
    }
    
    }


  //firestarter tier 1 (presale)
  function mintfirestarter1(uint256 numberOfTokens) external payable {

    //check switches
    require(isMasterActive, 'Contract is not active');
    require(isFirestarterActive, 'This portion of minting is not active');
    require(_Firestarter1[msg.sender]);
    
    //supply check
    require(totalSupply() < NFT_MAX, 'All tokens have been minted');
    require(numberOfTokens > 0, 'You must mint more than 1 token');
    require(numberOfTokens <= FIRESTARTER1, 'Cannot purchase this many tokens');
    require(balanceOf(msg.sender) <= FIRESTARTER1,'You hit the max per wallet');
    
          if(numberOfTokens >= 5) {
    require(totalSupply() + numberOfTokens + 1 <= NFT_MAX, 'Purchase would exceed max supply');
         }
           if(numberOfTokens < 5) {
    require(totalSupply() + numberOfTokens <= NFT_MAX, 'Purchase would exceed max supply');
         }
   
    //calculate prices
    require(pricemain * numberOfTokens <= msg.value, 'ETH amount is not sufficient');

    //mint!
    
         if(numberOfTokens >= 5) {
    
    for (uint256 i = 0; i < numberOfTokens + 1; i++) {

      uint256 tokenId = totalSupply() + 1;
        totalFirestarter1Supply += 1;

      _safeMint(msg.sender, tokenId);
    }

    }
    
     if(numberOfTokens < 5) {
    
    for (uint256 i = 0; i < numberOfTokens; i++) {

      uint256 tokenId = totalSupply() + 1;
        totalFirestarter1Supply += 1;

      _safeMint(msg.sender, tokenId);
    }
    
    }
    
    }

  //firestarter tier 2 (presale)
  function mintfirestarter2(uint256 numberOfTokens) external payable {

    //check switches
    require(isMasterActive, 'Contract is not active');
    require(isFirestarterActive, 'This portion of minting is not active');
    require(_Firestarter2[msg.sender]);
    
    //supply check
    require(totalSupply() < NFT_MAX, 'All tokens have been minted');
    require(numberOfTokens > 0, 'You must mint more than 1 token');
    require(numberOfTokens <= FIRESTARTER2, 'Cannot purchase this many tokens');
    require(balanceOf(msg.sender) <= FIRESTARTER2,'You hit the max per wallet');
  
            if(numberOfTokens >= 5) {
    require(totalSupply() + numberOfTokens + 1 <= NFT_MAX, 'Purchase would exceed max supply');
         }
           if(numberOfTokens < 5) {
    require(totalSupply() + numberOfTokens <= NFT_MAX, 'Purchase would exceed max supply');
         }
   
    //calculate prices
    require(pricemain * numberOfTokens <= msg.value, 'ETH amount is not sufficient');

    //mint!
    
            if(numberOfTokens >= 5) {
    
    for (uint256 i = 0; i < numberOfTokens + 1; i++) {

      uint256 tokenId = totalSupply() + 1;
        totalFirestarter2Supply += 1;

      _safeMint(msg.sender, tokenId);
    }

    }
    
     if(numberOfTokens < 5) {
    
    for (uint256 i = 0; i < numberOfTokens; i++) {

      uint256 tokenId = totalSupply() + 1;
        totalFirestarter2Supply += 1;

      _safeMint(msg.sender, tokenId);
    }
    
    }
    
    }
  

  //adam bomb squad dependency mint (presale)
  function mintadambombsquad(uint256 numberOfTokens) external payable {

    //check contract balance
    uint checkbalance = adambombsquad.balanceOf(msg.sender);
    require(checkbalance > 0);

    //check switches
    require(isMasterActive, 'Contract is not active');
    require(isBombSquadActive, 'This portion of minting is not active');

    //supply check
    require(totalSupply() < NFT_MAX, 'All tokens have been minted');
    require(numberOfTokens > 0, 'You must mint more than 1 token');
    require(numberOfTokens <= ABS_MAX, 'Cannot purchase this many tokens');
           if(numberOfTokens >= 5) {
    require(totalSupply() + numberOfTokens + 1 <= NFT_MAX, 'Purchase would exceed max supply');
         }
           if(numberOfTokens < 5) {
    require(totalSupply() + numberOfTokens <= NFT_MAX, 'Purchase would exceed max supply');
         }
    require(balanceOf(msg.sender) <= ABS_MAX,'You hit the max per wallet');
   
    //calculate prices
    require(pricemain * numberOfTokens <= msg.value, 'ETH amount is not sufficient');

    //mint!
    
            if(numberOfTokens >= 5) {
    
    for (uint256 i = 0; i < numberOfTokens + 1; i++) {

      uint256 tokenId = totalSupply() + 1;
        totalBombSquadSupply += 1;

      _safeMint(msg.sender, tokenId);
    }

    }
    
     if(numberOfTokens < 5) {
    
    for (uint256 i = 0; i < numberOfTokens; i++) {

      uint256 tokenId = totalSupply() + 1;
        totalBombSquadSupply += 1;

      _safeMint(msg.sender, tokenId);
    }
    
    }
    
    }
    
  //public mint
  function mintpublic(uint256 numberOfTokens) external payable {

    //check switches
    require(isMasterActive, 'Contract is not active');
    require(isPublicActive, 'This portion of minting is not active');

    //supply check
    require(totalSupply() < NFT_MAX, 'All tokens have been minted');
    require(numberOfTokens > 0, 'You must mint more than 1 token');
    require(numberOfTokens <= PURCHASE_LIMIT, 'Cannot purchase this many tokens');
           if(numberOfTokens >= 5) {
    require(totalSupply() + numberOfTokens + 1 <= NFT_MAX, 'Purchase would exceed max supply');
         }
           if(numberOfTokens < 5) {
    require(totalSupply() + numberOfTokens <= NFT_MAX, 'Purchase would exceed max supply');
         }
   
    //calculate prices
    require(pricemain * numberOfTokens <= msg.value, 'ETH amount is not sufficient');

    //mint!
            if(numberOfTokens >= 5) {
    
    for (uint256 i = 0; i < numberOfTokens + 1; i++) {

      uint256 tokenId = totalSupply() + 1;
        totalPublicSupply += 1;

      _safeMint(msg.sender, tokenId);
    }

    }
    
     if(numberOfTokens < 5) {
    
    for (uint256 i = 0; i < numberOfTokens; i++) {

      uint256 tokenId = totalSupply() + 1;
        totalPublicSupply += 1;

      _safeMint(msg.sender, tokenId);
    }
    
    }
    
    
    }
    

    //airdrop for original contract: 0xab20d7517e46a227d0dc7da66e06ea8b68d717e1
    // no limit due to to airdrop going directly to the 447 owners
  function airdrop(address[] calldata to) external  onlyOwner {
    require(totalSupply() < NFT_MAX, 'All tokens have been minted');

    for(uint256 i = 0; i < to.length; i++) {
      uint256 tokenId = totalSupply() + 1;
        totalAirdropSupply += 1;

      _safeMint(to[i], tokenId);
    }
  }

    
    //reserve
   // no limit due to to airdrop going directly to addresses
  function reserve(address[] calldata to) external  onlyOwner {
    require(totalSupply() < NFT_MAX, 'All tokens have been minted');

    for(uint256 i = 0; i < to.length; i++) {
      uint256 tokenId = totalSupply() + 1;
        totalReserveSupply += 1;

      _safeMint(to[i], tokenId);
    }
  }


  //switches
  function MasterActive(bool _isMasterActive) external override onlyOwner {
    isMasterActive = _isMasterActive;
  }
  
    function PublicActive(bool _isPublicActive) external override onlyOwner {
    isPublicActive = _isPublicActive;
  }
  
    function WhitelistActive(bool _isWhitelistActive) external override onlyOwner {
    isWhitelistActive = _isWhitelistActive;
  }
  
    function PresaleActive(bool _isPresaleActive) external override onlyOwner {
    isPresaleActive = _isPresaleActive;
  }
  
      function FirestarterActive(bool _isFirestarterActive) external override onlyOwner {
    isFirestarterActive = _isFirestarterActive;
  }
  
        function BombSquadActive(bool _isBombSquadActive) external override onlyOwner {
    isBombSquadActive = _isBombSquadActive;
  }

  //withdraw    
  address Address1 = 0xBEA1A871cf6BF1fE159D2Db2dFD46D9f5FFd5C15; //nickydiamonds.eth
    
      function withdraw() onlyOwner public {
        uint balance = address(this).balance;
        payable(Address1).transfer(balance*100/100);
        payable(msg.sender).transfer(address(this).balance);
  }
    

  //metadata
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