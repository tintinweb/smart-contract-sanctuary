// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./Context.sol";
import './ReentrancyGuard.sol';
import './Ownable.sol';
import './Strings.sol';
import "./Counters.sol";

contract SurrealDoge is 
    Context,
    ERC721Enumerable,
    ERC721Burnable,
    ReentrancyGuard,
    Ownable {
  using Counters for Counters.Counter;
  using Strings for uint256;

  uint256 public constant maxTokens = 10000;
  uint256 public constant transactionLimit = 25;

  uint256 public startTime;
  uint256 public unitPrice;
  string public baseTokenURI;
  
  string private constant extension = ".json";

  uint256 private promotionalMints = 0;
  Counters.Counter private _tokenIdTracker;

  event TokensMinted();
  event PriceChanged(uint256 newUnitPrice);

  constructor() ERC721('SurrealDoge', 'SRD') {
    unitPrice = 0.08 ether;
    startTime = 1634299200;
  }

  function tokenURI(uint256 _tokenId) public view override returns (string memory) {
    require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
    return bytes(baseTokenURI).length > 0 ? string(abi.encodePacked(baseTokenURI, _tokenId.toString(), extension)) : "";
  }
  
  function mintingAvailable() public view returns (bool) {
      return startTime <= block.timestamp && _tokenIdTracker.current() < maxTokens;
  }

  function promotionalMint(uint256 _amount) public onlyOwner returns (bool) {
    require(promotionalMints + _amount <= 50, "Can't mint anymore tokens for promotion");
    require(_tokenIdTracker.current() + _amount <= maxTokens, "Amount overflows total supply");

    mintLoop(_amount);

    promotionalMints += _amount;
      
    return true;
  }

  function publicMint(uint256 _amount) public payable nonReentrant returns (bool) {
    require(startTime <= block.timestamp, "Minting hasn't started");
    require(_amount <= transactionLimit, "Cannot bulk buy more than the preset limit");
    require(_tokenIdTracker.current() + _amount <= maxTokens, "Amount overflows total supply");
    require(msg.value == unitPrice * _amount, "You need to send 0.08 ether per mint");

    mintLoop(_amount);

    return true;
  }
  
  function mintLoop(uint256 _amount) private {
    for (uint256 i = 0; i < _amount; i++) {
      _mint(_msgSender(), _tokenIdTracker.current());
      _tokenIdTracker.increment();
    }

    emit TokensMinted();
  }

  function setBaseTokenURI(string memory _baseTokenURI) public onlyOwner {
    baseTokenURI = _baseTokenURI;
  }

  function setUnitPrice(uint256 _unitPrice) public onlyOwner {
    unitPrice = _unitPrice;
    emit PriceChanged(_unitPrice);
  }

  function setStartTime(uint256 _startTime) public onlyOwner {
    startTime = _startTime;
  }
  
  function withdraw() public onlyOwner {
    uint balance = address(this).balance;
    payable(owner()).transfer(balance);
  }
  
  function _beforeTokenTransfer(
      address from,
      address to,
      uint256 tokenId
  ) internal virtual override(ERC721, ERC721Enumerable) {
      super._beforeTokenTransfer(from, to, tokenId);
  }

  function supportsInterface(bytes4 interfaceId)
      public
      view
      virtual
      override(ERC721, ERC721Enumerable)
      returns (bool)
  {
      return super.supportsInterface(interfaceId);
  }
}