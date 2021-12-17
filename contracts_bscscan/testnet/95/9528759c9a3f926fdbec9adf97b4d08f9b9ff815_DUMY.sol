// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./ERC721Upgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./StringsUpgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./Initializable.sol";

contract DUMY is
  Initializable,
  OwnableUpgradeable,
  ERC721Upgradeable,
  ERC721EnumerableUpgradeable,
  UUPSUpgradeable
{
  using StringsUpgradeable for uint256;
  string public baseURI;
  string public baseExtension = ".json";
  string public notRevealedUri;
  
  uint256 public cost = 0.08 ether;
  uint256 public maxSupply = 10000;
  uint256 public maxMintAmount = 9;
  uint256 public nftPerAddressLimit = 3;
  uint256 public innovatorLimit = 4;
  uint256 public earlyAdapterLimit = 3;
  uint256 public preSaleLimit = 300;
  uint256 public preSaleCount = 0;
  
  
  bool public paused = false;
  bool public revealed = false;
  bool public onlyWhitelisted = false;
  bool public onlyInnovators = false;
  bool public onlyEarlyAdopters = false;
  
  address[] public whitelistedAddresses;
  address[] public innovatorWhitelistedAddresses;
  address[] public earlyAdopterWhitelistedAddresses;
  
  mapping(address => uint256) public addressMintedPresaleBalance;
  mapping(address => uint256) public addressMintedInnvatorBalance;
  mapping(address => uint256) public addressMintedEarlyAdopterBalance;
  
  constructor() initializer {}
  
  function initialize(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI,
    string memory _initNotRevealedUri
    
  ) public initializer {
    __Ownable_init();
    __ERC721_init(_name, _symbol);
    __ERC721Enumerable_init();
    __UUPSUpgradeable_init();
    baseURI = _initBaseURI;
    notRevealedUri = _initNotRevealedUri;
    setBaseURI(baseURI);
    setNotRevealedURI(notRevealedUri);
  }
  
  function _authorizeUpgrade(address newImplmentation) 
  internal 
  override
  onlyOwner{}
  
  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

    // public
  function mint(uint256 _mintAmount) public payable {
    require(!paused, "the contract is paused");
    uint256 supply = totalSupply();
    require(_mintAmount > 0, "need to mint at least 1 NFT");
    require(_mintAmount <= maxMintAmount, "max mint amount per session exceeded");
    require(supply + _mintAmount <= maxSupply, "max NFT limit exceeded");

    if (msg.sender != owner()) {
        if(onlyWhitelisted == true) {
            require(preSaleCount + supply <= preSaleLimit, 'Limit exceeded for presale');
            require(isWhitelisted(msg.sender), "user is not whitelisted");
            uint256 ownerMintedCount = addressMintedPresaleBalance[msg.sender];
            require(ownerMintedCount + _mintAmount <= nftPerAddressLimit, "max NFT per address exceeded");
        }
        else if (onlyInnovators == true){
            require(isInnovator(msg.sender), "user is not Innovator");
            uint256 ownerMintedCount = addressMintedInnvatorBalance[msg.sender];
            require(ownerMintedCount + _mintAmount <= innovatorLimit, "max NFT per address exceeded");
            require(msg.value >= cost * _mintAmount, "insufficient funds");
        }
        else if (onlyEarlyAdopters == true){
            require(isEarlyAdopter(msg.sender), "user is not Early Adopter");
            uint256 ownerMintedCount = addressMintedEarlyAdopterBalance[msg.sender];
            require(ownerMintedCount + _mintAmount <= earlyAdapterLimit, "max NFT per address exceeded");
            require(msg.value >= cost * _mintAmount, "insufficient funds");
        }
        else{
            require(msg.value >= cost * _mintAmount, "insufficient funds");
        }
        
    }

    for (uint256 i = 0; i < _mintAmount; i++) {
        if (onlyWhitelisted == true){
            preSaleCount++;
            addressMintedPresaleBalance[msg.sender]++;
        }
        else if (onlyInnovators == true){
            addressMintedInnvatorBalance[msg.sender]++;
        }
        else if(onlyEarlyAdopters == true){
            addressMintedEarlyAdopterBalance[msg.sender]++;
        }
      
      _safeMint(msg.sender, supply + i);
    }
  }
  
  function isWhitelisted(address _user) public view returns (bool) {
      
      for (uint i = 0; i < whitelistedAddresses.length; i++) {
          if (whitelistedAddresses[i] == _user) {
              return true;
      }
    }
    return false;
  }
  function isInnovator(address _user) public view returns (bool) {
      
      for (uint i = 0; i < innovatorWhitelistedAddresses.length; i++) {
          if (innovatorWhitelistedAddresses[i] == _user) {
              return true;
      }
    }
    return false;
  }
  function isEarlyAdopter(address _user) public view returns (bool) {
      
      for (uint i = 0; i < earlyAdopterWhitelistedAddresses.length; i++) {
          if (earlyAdopterWhitelistedAddresses[i] == _user) {
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
  
  function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
  
  function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }
  
  function airDrop(address to, uint256 tokenId) public  onlyOwner {
        safeTransferFrom(address (msg.sender),to,tokenId);
  }

  //only owner
  function reveal() public onlyOwner() {
      revealed = true;
  }
  
  function addWhitelisting(address[] memory _addresses) public onlyOwner{
      whitelistedAddresses = _addresses;
  }
  function addInnovatorWhitelisting(address[] memory _addresses) public onlyOwner{
      innovatorWhitelistedAddresses = _addresses;
  }
  function addEarlyAdopterWhitelisting(address[] memory _addresses) public onlyOwner{
      earlyAdopterWhitelistedAddresses = _addresses;
  }
  
  function setNftPerAddressLimit(uint256 _limit) public onlyOwner() {
    nftPerAddressLimit = _limit;
  }
  
  function setCost(uint256 _newCost) public onlyOwner() {
    cost = _newCost;
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
  
  function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
    notRevealedUri = _notRevealedURI;
  }

  function pause(bool _state) public onlyOwner {
    paused = _state;
  }
  
 
  function withdraw() public onlyOwner {
    (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
    require(success);
  }
}