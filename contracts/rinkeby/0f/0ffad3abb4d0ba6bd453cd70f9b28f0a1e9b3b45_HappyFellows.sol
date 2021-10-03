// SPDX-License-Identifier: Unlicensed

// @title Happy Fellow
// @author Happy Fellow's Team

pragma solidity >=0.8.0;

import "ERC721Enumerable.sol";
import "Ownable.sol";

contract HappyFellows is ERC721Enumerable, Ownable {
  using Strings for uint256;

  string public baseURI;
  string public baseExtension = ".json";
  uint256 public cost = 0.05 ether;
  uint256 public maxSupply = 2000;
  uint256 public maxMintAmount = 10;
  bool public paused = false;
  bool private forsale = false;


// Initial deployment 
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

  //only owner
  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

function toggleForSale() public onlyOwner {
        forsale = !forsale;
    }

  function pause(bool _state) public onlyOwner {
    paused = _state;
  }
 

  function withdraw() public payable onlyOwner {
    require(payable(msg.sender).send(address(this).balance));
  }
}