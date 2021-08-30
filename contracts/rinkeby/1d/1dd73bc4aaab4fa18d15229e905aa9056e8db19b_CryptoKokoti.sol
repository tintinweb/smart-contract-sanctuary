// SPDX-License-Identifier: None

pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC721Enumerable.sol";

contract CryptoKokoti is Ownable, ERC721Enumerable {
  using SafeMath for uint256;

  uint256 public constant mintPrice = 0.05 ether;
  uint256 public constant mintLimit = 25;

  uint256 public supplyLimit = 1000;
  uint256 public presaleStartTime = 1630321291; // Fri Aug 27 2021 03:11:00 GMT+0000
  uint256 public saleStartTime = 1630321291; // Fri Aug 27 2021 15:11:00 GMT+0000

  string public baseURI;

  mapping(address => bool) private _presaleWhitelist;

  address private creatorAddress = 0xa36C2A49cfe927f6335bE25326c9eeE26BeF9b73; // creator
  address private devAddress = 0xa36C2A49cfe927f6335bE25326c9eeE26BeF9b73; // developer
  address private marketingAddress = 0xAeE8ba9F3a6D4B7976b0095a05Cea126A04Fdac7; // marketing

  constructor(
    string memory inputBaseUri
  ) ERC721("Crypto-Kokotiny by Ondrej", "CK") { 
    baseURI = inputBaseUri;
  }

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  function setBaseURI(string calldata newBaseUri) external onlyOwner {
    baseURI = newBaseUri;
  }
  
  function preSaleActive() public view returns(bool) {
    return block.timestamp > presaleStartTime && block.timestamp < saleStartTime;
  }
  
  function saleActive() public view returns(bool) {
    return block.timestamp > saleStartTime;
  }
  
  modifier onlyPresaleWhitelist {
    require(_presaleWhitelist[msg.sender], "Not on presale whitelist");
    _;
  }

  function addToWhitelist(address[] memory wallets) public onlyOwner {
    for(uint i = 0; i < wallets.length; i++) {
      _presaleWhitelist[wallets[i]] = true;
    }
  }

  function isOnWhitelist(address wallet) public view returns (bool) {
    return _presaleWhitelist[wallet];
  }

  function buyPresale(uint numberOfTokens) external onlyPresaleWhitelist payable {
    require(preSaleActive(), "Presale is not active");
    require(numberOfTokens <= mintLimit, "Too many tokens for one transaction");
    require(msg.value >= mintPrice.mul(numberOfTokens), "Insufficient payment");

    _mint(numberOfTokens);
  }

  function buy(uint numberOfTokens) external payable {
    require(saleActive(), "Sale is not active");
    require(numberOfTokens <= mintLimit, "Too many tokens for one transaction");
    require(msg.value >= mintPrice.mul(numberOfTokens), "Insufficient payment");

    _mint(numberOfTokens);
  }

  function _mint(uint numberOfTokens) private {
    require(totalSupply().add(numberOfTokens) <= supplyLimit, "Not enough tokens left");

    uint256 newId = totalSupply();
    for(uint i = 0; i < numberOfTokens; i++) {
      newId += 1;
      _safeMint(msg.sender, newId);
    }
  }

  function reserve(uint256 numberOfTokens) external onlyOwner {
    _mint(numberOfTokens);
  }

  function withdraw() external onlyOwner {
    require(address(this).balance > 0, "No balance to withdraw");
    
    uint devShare = address(this).balance.mul(10).div(100);
    uint marketingShare = address(this).balance.mul(5).div(100);

    (bool success, ) = devAddress.call{value: devShare}("");
    require(success, "Withdrawal failed");
    
    (success, ) = marketingAddress.call{value: marketingShare}("");
    require(success, "Withdrawal failed");
    
    (success, ) = creatorAddress.call{value: address(this).balance}("");
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