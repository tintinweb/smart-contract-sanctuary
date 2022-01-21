// SPDX-License-Identifier: GPL-3.0


pragma solidity >=0.7.1 <0.9.0;

import "Ownable.sol";
import "ERC721Enumerable.sol";

contract Rakhun is ERC721Enumerable, Ownable {
  using Strings for uint256;

  string public baseURI;
  string public baseExtension = ".json";
  uint256 public cost = 15 ether;
  uint256 public maxSupply = 6399;
  uint256 public maxMintAmount = 99;
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

                    if(supply < 25){
                    onlyLeftNFT = 25 - supply;

                    require(onlyLeftNFT >=_mintAmount, "More than available");
                    require(msg.value >= 15 ether * _mintAmount);
                    

                    }

                    
                    if(25 <= supply && supply < 50){
                    onlyLeftNFT = 50 - supply;
                    require(onlyLeftNFT >=_mintAmount, "More than available");
                    require(msg.value >= 30 ether * _mintAmount);
                    
                    }

                    
                    if(50 <= supply && supply < 100){
                    onlyLeftNFT = 100 - supply;

                    require(onlyLeftNFT >=_mintAmount, "More than available");
                    require(msg.value >= 90 ether * _mintAmount);
                    
                                      
                    }
                    
                    
                    if(100 <= supply && supply < 200){
                    onlyLeftNFT = 200 - supply;
                    require(onlyLeftNFT >=_mintAmount, "More than available");
                    require(msg.value >= 180 ether * _mintAmount);
                    
                    }

                    
                    if(200 <= supply && supply < 300){
                    onlyLeftNFT = 300 - supply;
                    require(onlyLeftNFT >=_mintAmount, "More than available");
                    require(msg.value >= 360 ether * _mintAmount);
                    
                    }

                    if(300 <= supply && supply < 400){
                    onlyLeftNFT = 400 - supply;
                    require(onlyLeftNFT >=_mintAmount, "More than available");
                    require(msg.value >= 540 ether * _mintAmount);
                    
                    }

                      if(400 <= supply && supply < 500){
                    onlyLeftNFT = 500 - supply;
                    require(onlyLeftNFT >=_mintAmount, "More than available");
                    require(msg.value >= 720 ether * _mintAmount);
                    
                    }  if(500 <= supply && supply < 750){
                    onlyLeftNFT = 750 - supply;
                    require(onlyLeftNFT >=_mintAmount, "More than available");
                    require(msg.value >= 900 ether * _mintAmount);
                    
                    }

                      if(750 <= supply && supply < 1000){
                    onlyLeftNFT = 1000 - supply;
                    require(onlyLeftNFT >=_mintAmount, "More than available");
                    require(msg.value >= 1080 ether * _mintAmount);
                    
                    }

                    	if (supply >= 1000) {
                    onlyLeftNFT = 6399 - supply;
                    require(onlyLeftNFT >=_mintAmount, "More than available");
                    require(msg.value >= 1260 ether * _mintAmount);				            
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