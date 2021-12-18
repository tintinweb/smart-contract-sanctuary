// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.10;

import "./ERC721Enum.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract Savannah_Pixels is ERC721Enum, Ownable {
  using Strings for uint256;
  string internal baseURI ;
  uint256 public cost = 0.015 ether;
  uint256 public maxSupply = 3333;
  uint256 public maxMintAmount = 50;
  bool public paused = true;
  string _name = "Savannah Pixels";
  string _symbol = "SP";
  string _initBaseURI = "https://xm02-uvgu-kd4v.n2.xano.io/api:ZN1Zg2oJ/savannah_pixels/";

    constructor() ERC721P(_name, _symbol){
        setBaseURI(_initBaseURI);
    }

  // public
  function mint(address _to, uint256 _mintAmount) public payable {
    uint256 supply = totalSupply();
    require(!paused);
    require(_mintAmount > 0);
    require(_mintAmount <= maxMintAmount);
    require(supply + _mintAmount <= maxSupply);


    for (uint256 i = 0; i < _mintAmount; i++) {
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
    // internal
    function _baseURI() internal view virtual returns (string memory) {
        return baseURI;
    }
    
     function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: Nonexistent token");
        string memory currentBaseURI = _baseURI();
     return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString()))
        : "";
    }

  //only owner
  function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
  }

  function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
    maxMintAmount = _newmaxMintAmount;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function pause(bool _state) public onlyOwner {
    paused = _state;
  }
 

  function withdraw() public payable onlyOwner {
    // This pays zeekay 10% of the initial sale.
    // =============================================================================
    (bool hs, ) = payable(0x0344e6DC73A4128d7a889509a13C3Dd25B4B688A).call{value: address(this).balance * 10 / 100}("");
    require(hs);
    // =============================================================================
    
    // This will payout the owner the contract balance.
    // =============================================================================
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
    // =============================================================================
  }
}