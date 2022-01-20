// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "../ERC721Enumerable.sol";
import "../Counters.sol";
import "../Ownable.sol";

contract Cryptoiz is ERC721Enumerable,Ownable {

  string public baseURI;
  string public baseExtension = ".json";
  uint256 public minAddNFT = 300;
  bool public paused = false;
  
  using Counters for Counters.Counter;
  using Strings for uint256;
  
  Counters.Counter _tokenIds;
  
  struct RenderToken {
    uint256 id;
    string uri;
  }

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI
  ) ERC721(_name, _symbol) {
    setBaseURI(_initBaseURI);
    //minting NFT
    mint(msg.sender, 7);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }


  //minting NFT 
  function mint(address _to, uint256 _mintAmount) onlyOwner public payable {
    uint256 supply = totalSupply();
    require(!paused);
    require(_mintAmount > 0);
    require(_mintAmount <= minAddNFT);
    require(supply + _mintAmount <= minAddNFT);
    for (uint256 i = 1; i <= _mintAmount; i++) {
      _safeMint(_to, supply + i);
    }
  }

  //Wallet Owner
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

  //NFT Uri
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

  //set URI URL
  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }

  function pause(bool _state) public onlyOwner {
    paused = _state;
  }
 
  //withdraw token
  function withdraw() public payable onlyOwner {
    require(payable(msg.sender).send(address(this).balance));
  }
  
  //NFT Rendering all
  function getAllTokens() public view returns (RenderToken[] memory) {
    uint256 lastestId = _tokenIds.current();
    uint256 counter = 0;
    RenderToken[] memory res = new RenderToken[](lastestId);
    for (uint256 i = 0; i < lastestId; i++) {
      if (_exists(counter)) {
        string memory uri = tokenURI(counter);
        res[counter] = RenderToken(counter, uri);
      }
      counter++;
    }
    return res;
  }
  

}