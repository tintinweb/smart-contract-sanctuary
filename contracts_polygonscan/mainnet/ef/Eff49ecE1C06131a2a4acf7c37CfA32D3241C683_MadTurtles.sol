// SPDX-License-Identifier: GPL-3.0


pragma solidity >=0.7.0 <0.9.0;

import "ERC721Enumerable.sol";
import "Ownable.sol";

contract MadTurtles is ERC721Enumerable, Ownable {
  using Strings for uint256;

  string public baseURI;
  string public baseExtension = ".json";
  uint256 public cost = 40 ether;
  uint256 public maxSupply = 10000;
  uint256 public maxMintAmount = 499;
  uint256 public onlyLeftNFT;

  bool public paused = false;
  bool public revealed = false;
  string public notRevealedUri;
  mapping(address => bool) public whitelisted;

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI,
    string memory _initNotRevealedUri
  ) ERC721(_name, _symbol) {
    setBaseURI(_initBaseURI);
    setNotRevealedURI(_initNotRevealedUri);
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  // public
  function mint(address _to, uint256 _mintAmount) public payable {
    uint256 supply = totalSupply();
    require(!paused);
    require(_mintAmount > 0);
    require(_mintAmount <= maxMintAmount);
    require(supply + _mintAmount <= maxSupply);

    if (msg.sender != owner()) {
        if(whitelisted[msg.sender] != true) {

                    if(supply < 750){
                    onlyLeftNFT = 750 - supply;

                    require(onlyLeftNFT >=_mintAmount, "More than available");
                    require(msg.value >= 40 ether * _mintAmount);
                    

                    }

                    
                    if(750 <= supply && supply < 2500){
                    onlyLeftNFT = 2500 - supply;
                    require(onlyLeftNFT >=_mintAmount, "More than available");
                    require(msg.value >= 50 ether * _mintAmount);
                    
                    }

                    
                    if(2500 <= supply && supply < 3500){
                    onlyLeftNFT = 3500 - supply;

                    require(onlyLeftNFT >=_mintAmount, "More than available");
                    require(msg.value >= 70 ether * _mintAmount);
                    
                                      
                    }
                    
                    
                    if(3500 <= supply && supply < 5000){
                    onlyLeftNFT = 5000 - supply;
                    require(onlyLeftNFT >=_mintAmount, "More than available");
                    require(msg.value >= 100 ether * _mintAmount);
                    
                    }

                    
                    if(5000 <= supply && supply < 7500){
                    onlyLeftNFT = 7500 - supply;
                    require(onlyLeftNFT >=_mintAmount, "More than available");
                    require(msg.value >= 150 ether * _mintAmount);
                    
                    }

                    if(7500 <= supply && supply < 10000){
                    onlyLeftNFT = 10000 - supply;
                    require(onlyLeftNFT >=_mintAmount, "More than available");
                    require(msg.value >= 200 ether * _mintAmount);
                    
                    }



        }
    }

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
  
  function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
  }

  function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
    maxMintAmount = _newmaxMintAmount;
  }
  
  function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
    notRevealedUri = _notRevealedURI;
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
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
  }

}