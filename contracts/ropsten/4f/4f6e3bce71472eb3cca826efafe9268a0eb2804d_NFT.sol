// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

 contract NFT is ERC721Enumerable, Ownable {
  using Strings for uint256;
  string public baseURI;
  string public baseExtension = ".json";
  string public notRevealedUri;
  uint256 public cost = 0.1 ether;
  
  uint256 public maxSupply = 3000;
  uint256 public maxMintAmount = 20;
  uint256 public nftPerAddressesLimit = 3;
  bool public paused = false;
  bool public revealed = false;
  bool public OnlyWhiteListed = true;
  address[] public whitelistedAddresses;
  mapping (address => uint256) public addressMintBalence;
  
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
  function mint( uint256 _mintAmount) public payable {
    require(msg.value >= _mintAmount*cost);
    require(!paused);
    uint256 supply = totalSupply();
    require(_mintAmount >= 0);  
    require(msg.value + addressMintBalence[msg.sender] <= maxMintAmount);
    require(supply + _mintAmount <= maxSupply);
    //require(whitelistedAddresses + _mintAmount);
   if (msg.sender != owner()) {
        if (OnlyWhiteListed){
        require(isWhitelisted(msg.sender),"User is not WhiteListed");
        uint256 ownerMintedCount = addressMintBalence[msg.sender];
        require ((ownerMintedCount + _mintAmount <= nftPerAddressesLimit),"Limit Reached");
        }
        require(msg.value == cost * _mintAmount);   
        }
    
    for (uint256 i = 1; i <= _mintAmount; i++) {
      addressMintBalence[msg.sender] ++;
      _safeMint(msg.sender, supply + i);
    }
}
   
  function isWhitelisted(address _users) public view returns(bool){
    for(uint256 i = 0; i < whitelistedAddresses.length;i ++ ){
     if (whitelistedAddresses[i]== _users){
         return true;
     }
    }
         return false;
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
    nftPerAddressesLimit = _limit;
  }
  function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
  }

  function setAfterPresaleCost() public  onlyOwner {

    require(OnlyWhiteListed==false,"First disable Presale");

    cost = 1 ether;
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
  function setOnlyWhiteListed(bool _state) public onlyOwner {
    OnlyWhiteListed = _state;
  }

 
 function whitelistUsers(address[] calldata _users ) public onlyOwner {
     delete whitelistedAddresses;
     whitelistedAddresses = _users;
  }
 

  function withdraw() public payable onlyOwner {
    
    (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
    require(success);
    /**
    ["0x5B38Da6a701c568545dCfcB03FcB875f56beddC4",
    "0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2",
    "0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db",
    "0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB",
    "0x617F2E2fD72FD9D5503197092aC168c91465E7f2"]
    */
  }
}