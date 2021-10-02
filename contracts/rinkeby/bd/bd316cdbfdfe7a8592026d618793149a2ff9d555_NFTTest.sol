// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './ReentrancyGuard.sol';
import './ERC721PresetMinterPauserAutoId.sol';
import './Ownable.sol';
import './Strings.sol';

contract NFTTest is ERC721PresetMinterPauserAutoId, ReentrancyGuard, Ownable {
  using Counters for Counters.Counter;
  using Strings for uint256;

  uint256 public constant maxTokens = 3;
  uint256 public constant transactionLimit = 25;

  uint256 public unitPrice;
  string public baseURI;
  
  string private constant extension = ".json";

  event TokensMinted();
  event PriceChanged(uint256 newUnitPrice);

  constructor() ERC721PresetMinterPauserAutoId('NFTTest', 'TEST') {
    unitPrice = 0.001 ether;
    pause();
  }

  function tokenURI(uint256 _tokenId) public view override returns (string memory) {
    require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

    return string(abi.encodePacked(baseURI, _tokenId.toString(), extension));
  }

  function setUnitPrice(uint256 newUnitPrice) public onlyOwner {
    unitPrice = newUnitPrice;
    emit PriceChanged(newUnitPrice);
  }

  function publicMint(uint256 _amount) public payable nonReentrant returns(bool) {
    require(_amount <= transactionLimit, "Cannot bulk buy more than the preset limit");
    require(_tokenIdTracker.current() + _amount <= maxTokens, "Total supply reached");
    require(msg.value == unitPrice * _amount, "You need to send 0.08 ether per mint");

    mintLoop(_msgSender(), _amount);

    return true;
  }

  function setBaseURI(string memory _baseURI) public onlyOwner {
    baseURI = _baseURI;
  }

  function withdraw() public onlyOwner {
    uint balance = address(this).balance;
    payable(owner()).transfer(balance);
  }

  function mintLoop(address _sender, uint256 _amount) private {
    for (uint256 i = 0; i < _amount; i++) {
      super.mint(_sender);
    }
    emit TokensMinted();
  }
}