// SPDX-License-Identifier: GPL-3.0

// Created by HashLips
// The Nerdy Coder Clones

pragma solidity >=0.8.0;

import "ERC721Enumerable.sol";
import "Ownable.sol";

contract HFT is ERC721Enumerable, Ownable {
  using Strings for uint256;

  string public baseURI;
  string public baseExtension = ".json";
  uint256 public cost = 0.05 ether;
  uint256 public maxSupply = 5000;
  uint256 public maxMintAmount = 10;
  bool public paused = false;
  mapping(address => bool) public whitelisted;
  bool private forsale = false;

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI
  ) ERC721(_name, _symbol) {
    setBaseURI(_initBaseURI);
    
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  // public
   function mint(address _to, uint256 _mintAmount) public payable {
    uint256 supply = totalSupply();
    require(forsale == true, "Not for sale yet!");
    require(_mintAmount > 0);
    require(_mintAmount <= maxMintAmount, "Can not mint more than the 10 at a given time");
    require(supply + _mintAmount <= maxSupply, "Not enough tokens available");
    require(msg.value >= cost*(_mintAmount), "Value below price");
    for (uint256 i = 1; i <= _mintAmount; i++) {
      _safeMint(_to, supply + i);
    }
  }

  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    for (uint256 i; i < ownerTokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokenIds;
  }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }

  //only owner
  function setCost(uint256 _newCost) public onlyOwner() {
    cost = _newCost;
  }
  
  function toggleForSale() public onlyOwner {
        forsale = !forsale;
    }

  function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner() {
    maxMintAmount = _newmaxMintAmount;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }

  function pause(bool _state) public onlyOwner {
    paused = _state;
  }
 
 function whitelistUser(address _user) public onlyOwner {
    whitelisted[_user] = true;
  }
 
  function removeWhitelistUser(address _user) public onlyOwner {
    whitelisted[_user] = false;
  }

  function withdraw() public payable onlyOwner {
    require(payable(msg.sender).send(address(this).balance));
  }
}