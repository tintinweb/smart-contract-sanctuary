// SPDX-License-Identifier: GPL-3.0

// Created by Ali Razzaq 
// Contact [email protected]

pragma solidity >=0.7.0 <0.9.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract CrocNFT is ERC721Enumerable, Ownable {

  using Strings for uint256;

  string internal baseURI;
  string public baseExtension = ".json";
  string internal notRevealedUri;

  uint256 public cost = 0.077 ether;  //77000000000000000
  uint256 public preSaleCost = 0.066 ether;  //66000000000000000

  uint256 public presaleStartTime = 1638367200;

  uint256 public presaleEndTime = 1638453600;

  uint256 public maxSupply = 7575;
  
  uint256 public maxMintAmount = 10;
  uint256 public nftPerAddressLimit = 10;

  bool public paused = false;
  bool public revealed = false;
  bool public onlyWhitelisted = true;
  
  mapping(address => bool) public isWhitelisted;
  mapping(address => uint256) public addressMintedBalance;


  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI,
    string memory _initNotRevealedUri
  ) ERC721(_name, _symbol) {
    setBaseURI(_initBaseURI);
    setNotRevealedURI(_initNotRevealedUri);
  }

  function setPresaleTime(uint _start, uint _end) public onlyOwner {
    presaleStartTime = _start;
    presaleEndTime = _end;
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  // public
  function mint(uint256 _mintAmount) public payable {
      
    require(!paused, "the contract is paused");
    require(_mintAmount > 0, "need to mint at least 1 NFT");
    
    uint256 supply = totalSupply();
    require(supply + _mintAmount <= maxSupply, "max NFT limit exceeded");

    if (msg.sender != owner()) {
        
        require(block.timestamp > presaleStartTime, "Presale haven't begin yet");
        
        if(block.timestamp < presaleEndTime){
            // Presale
            
            require(isWhitelisted[msg.sender], "user is not whitelisted");
            uint256 ownerMintedCount = addressMintedBalance[msg.sender];
            require(ownerMintedCount + _mintAmount <= nftPerAddressLimit, "max NFT per address exceeded");
            require(_mintAmount <= maxMintAmount, "max mint amount per session exceeded");
            require(msg.value >= preSaleCost * _mintAmount, "insufficient funds");
            
        } else {
            // Public sale
            require(_mintAmount <= maxMintAmount, "max mint amount per session exceeded");
            require(msg.value >= cost * _mintAmount, "insufficient funds");
            
        }
        
    }
    
    for (uint256 i = 1; i <= _mintAmount; i++) {
        addressMintedBalance[msg.sender]++;
      _safeMint(msg.sender, supply + i);
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
    
    if(revealed == false) {
        return notRevealedUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }

  //only owner
  function reveal() public onlyOwner {
      revealed = true;
  }
  
  function setNftPerAddressLimit(uint256 _limit) public onlyOwner {
    nftPerAddressLimit = _limit;
  }
  
  function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
  }

  function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
    maxMintAmount = _newmaxMintAmount;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }
  
  function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
    notRevealedUri = _notRevealedURI;
  }

  function pause(bool _state) public onlyOwner {
    paused = _state;
  }
  
  function setOnlyWhitelisted(bool _state) public onlyOwner {
    onlyWhitelisted = _state;
  }
  
  function whitelistUsers(address[] memory _users) public onlyOwner {
    for (uint i = 0; i < _users.length; i++) {
        isWhitelisted[_users[i]] = true;
    }
  }
 
  function withdraw() public payable onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }

  function ETHbalance() public view onlyOwner returns (uint) {
    return address(this).balance;
  }
}