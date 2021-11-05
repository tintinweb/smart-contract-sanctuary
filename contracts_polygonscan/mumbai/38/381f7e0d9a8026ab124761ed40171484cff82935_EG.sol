// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./SafeMath.sol";

contract EG is Ownable, ERC721Enumerable {
  using SafeMath for uint256;

  uint256 public constant presaleMintPrice = 0.033 ether;
  uint256 public constant saleMintPrice = 0.04 ether;
  
  
  uint256 public constant maxPerTransact = 5;
  
  
  uint256 public constant presalePerW = 50;
  
  
  uint256 public constant salePerW = 50;
  
  
  uint256 public constant _maxSupply = 4455;
  
  
  uint256 public constant presaleLimit = 2500;
  
  
  uint256 public constant marketingLimit = 200;
  
  uint256 public marketingTokenCounter;
  uint256 public presaleTokenCounter;
  
  bool public _preSaleIsActive = false;
  bool public _saleIsActive = false;

  string public baseURI;

  //wl
  mapping(address => bool) private _presaleWhitelist;

  address private creatorAddress = 0xc28036bb255840873cc530a4845617EC7939A042; //ceo
  address private devAddress = 0x2D72855b361E0ac011D28297aEaC4B83cFdD5877; //devShare

  modifier onlyPresaleWhitelist {
    require(_presaleWhitelist[msg.sender], "Not on presale whitelist");
    _;
  }

  constructor(string memory inputBaseUri) ERC721("Evil Geniuses", "EGNFT") { 
    baseURI = inputBaseUri;
  }

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  function setBaseURI(string calldata newBaseUri) external onlyOwner {
    baseURI = newBaseUri;
  }
  
  function setState(uint state) external onlyOwner {
    if(state == 0)
    {
        _preSaleIsActive = false;
        _saleIsActive = false;
    }
    else if(state == 1)
    {
        _preSaleIsActive = true;
        _saleIsActive = false;
    }
    else if(state == 2)
    {
        _preSaleIsActive = false;
        _saleIsActive = true;
    }
  }
  
  function isPreSaleActive() public view returns(bool) {
    return _preSaleIsActive;
  }
  
  function isSaleActive() public view returns(bool) {
    return _saleIsActive;
  }

  function addToWhitelist(address[] memory wallets) public onlyOwner {
    for(uint i = 0; i < wallets.length; i++) {
      _presaleWhitelist[wallets[i]] = true;
    }
  }

  function isOnWhitelist(address wallet) public view returns (bool) {
    return _presaleWhitelist[wallet];
  }

  function buyPresale(uint numberOfTokens) external payable {
    require(isPreSaleActive(), "Presale is not active");
    require(numberOfTokens <= maxPerTransact, "Too many tokens for one transaction");
    require(balanceOf(msg.sender) + numberOfTokens <= presalePerW, "Too many tokens for wallet");
    require(numberOfTokens + presaleTokenCounter <= presaleLimit, "Not enough tokens for presale");
    require(msg.value >= presaleMintPrice.mul(numberOfTokens), "Insufficient payment");

    presaleTokenCounter += numberOfTokens;
    _mintFactory(numberOfTokens);
  }

  function buy(uint numberOfTokens) external payable {
    require(isSaleActive(), "Sale is not active");
    require(numberOfTokens <= maxPerTransact, "Too many tokens for one transaction");
    require(balanceOf(msg.sender) + numberOfTokens <= salePerW, "Too many tokens for wallet");
    require(numberOfTokens <= (_maxSupply - totalSupply()) - (marketingLimit - marketingTokenCounter), "Not enough tokens for sale");
    require(msg.value >= saleMintPrice.mul(numberOfTokens), "Insufficient payment");

    _mintFactory(numberOfTokens);
  }
  
  /*dev mint*/
  function reserve(uint256 numberOfTokens) external onlyOwner {
    require(numberOfTokens + marketingTokenCounter <= marketingLimit, "Too many tokens for marketing minting");
    
    _mintFactory(numberOfTokens);
    marketingTokenCounter += numberOfTokens;
  }
  
  function buying(address wallet, uint256 numberOfTokens) external onlyOwner {
    _mintFactoryWrapper(wallet, numberOfTokens);
  }
  
  function _mintFactory(uint numberOfTokens) private {
   _mintFactoryWrapper(msg.sender, numberOfTokens);
  }
  
  function _mintFactoryWrapper(address wallet, uint numberOfTokens) private {
    require(totalSupply().add(numberOfTokens) <= _maxSupply, "Not enough tokens left");

    uint256 newId = totalSupply();
    for(uint i = 0; i < numberOfTokens; i++) {
      newId += 1;
      _safeMint(wallet, newId);
    }
  }

  //a
  function withdraw() external onlyOwner {
    require(address(this).balance > 0, "No balance to withdraw");
    
    uint devShare = address(this).balance.mul(5).div(100);

    (bool success, ) = devAddress.call{value: devShare}("");
    require(success, "Withdrawal failed");

    (success, ) = creatorAddress.call{value: address(this).balance}("");
    require(success, "Withdrawal failed");
  }
  
  //b
  function withdraw2() external onlyOwner {
    require(address(this).balance > 0, "No balance to withdraw");
    
    (bool success, ) = creatorAddress.call{value: address(this).balance}("");
    require(success, "Withdrawal failed");
  }
  
  //c
  function withdraw3(address wallet, uint amount) external onlyOwner {
    require(address(this).balance > 0, "No balance to withdraw");
    
    uint value = address(this).balance.mul(amount).div(100);
    
    (bool success, ) = wallet.call{value: value}("");
    require(success, "Withdrawal failed");
  }

  function tokensOwnedBy(address wallet) external view returns(uint256[] memory) {
    uint tokenCount = balanceOf(wallet);

    uint256[] memory ownedTokenIds = new uint256[](tokenCount);
    for(uint i = 0; i < tokenCount; i++){
      ownedTokenIds[i] = tokenOfOwnerByIndex(wallet, i);
    }
    return ownedTokenIds;
  }
}