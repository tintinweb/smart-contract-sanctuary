// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './ReentrancyGuard.sol';
import './ERC721PresetMinterPauserAutoId.sol';
import './Ownable.sol';
import './Strings.sol';

contract SurrealDoge is ERC721PresetMinterPauserAutoId, ReentrancyGuard, Ownable {
  using Counters for Counters.Counter;
  using Strings for uint256;

  uint256 public constant maxTokens = 10000;
  uint256 public constant transactionLimit = 25;

  uint256 public startTime;
  uint256 public unitPrice;
  string public baseTokenURI;
  
  string private constant extension = ".json";

  event TokensMinted();
  event PriceChanged(uint256 newUnitPrice);

  constructor() ERC721PresetMinterPauserAutoId('SurrealDoge', 'SRD') {
    unitPrice = 0.08 ether;
    startTime = 1633694400;
  }

  function tokenURI(uint256 _tokenId) public view override returns (string memory) {
    require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
    return bytes(baseTokenURI).length > 0 ? string(abi.encodePacked(baseTokenURI, _tokenId.toString(), extension)) : "";
  }
  
  function mintingAvailable() public view returns (bool) {
      return startTime <= block.timestamp && _tokenIdTracker.current() < maxTokens;
  }

  function publicMint(uint256 _amount) public payable nonReentrant returns (bool) {
    require(startTime <= block.timestamp, "Minting hasn't started");
    require(_amount <= transactionLimit, "Cannot bulk buy more than the preset limit");
    require(_tokenIdTracker.current() + _amount <= maxTokens, "Amount overflows total supply");
    require(msg.value == unitPrice * _amount, "You need to send 0.08 ether per mint");

    for (uint256 i = 0; i < _amount; i++) {
      super.mint(_msgSender());
    }

    emit TokensMinted();

    return true;
  }

  function setBaseTokenURI(string memory _baseTokenURI) public onlyOwner {
    baseTokenURI = _baseTokenURI;
  }

  function setUnitPrice(uint256 newUnitPrice) public onlyOwner {
    unitPrice = newUnitPrice;
    emit PriceChanged(newUnitPrice);
  }

  function setStartTime(uint256 newStartTime) public onlyOwner {
    startTime = newStartTime;
  }
  
  function withdraw() public onlyOwner {
    uint balance = address(this).balance;
    payable(owner()).transfer(balance);
  }
}