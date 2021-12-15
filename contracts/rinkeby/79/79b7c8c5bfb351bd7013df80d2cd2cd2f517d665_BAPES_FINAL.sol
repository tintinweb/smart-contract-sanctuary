// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;


import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract BAPES_FINAL is ERC721Enumerable, Ownable {
  using Strings for uint256;
  string public baseURI;

  uint256 public constant MAX_SUPPLY = 10000;

  uint256 public PRESALE_PRICE = 0.07 ether;
  uint256 public REGULAR_PRICE = 0.08 ether;

  uint256 public PRESALE_MAX_PURCHASE = 100;
  uint256 public MAX_PURCHASE = 100;

  bool public REGULAR_SALE = false;
  bool public PRE_SALE = false;
  bool public FREE_SALE = false;

  mapping(address => bool) public whitelistedAddress;
  mapping(address => bool) public freeWhitelistedAddress;
  
  modifier onlyWhiteListed() {
    require(whitelistedAddress[_msgSender()], "not whitelisted");
    _;
  }

  constructor(string memory _name, string memory _symbol, string memory _initBaseURI) ERC721(_name, _symbol) {
    setBaseURI(_initBaseURI);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  //MINTING FUNCTIONS
  function mint(uint256 _mintAmount) public payable returns(bool) {
    require(REGULAR_SALE, "regular sale not started yet");
    require(msg.value >= REGULAR_PRICE * _mintAmount, "insufficient funds");
    require(balanceOf(_msgSender()) + _mintAmount <= MAX_PURCHASE,  "Can only mint 5 tokens");

    _mintNFT(_mintAmount);
    return true;
  }

  function mintForWhiteListed(uint256 _mintAmount) public payable onlyWhiteListed() returns(bool){
    require(PRE_SALE, "pre sale not started yet");
    require(msg.value >= PRESALE_PRICE * _mintAmount, "insufficient funds");
    require(balanceOf(_msgSender()) + _mintAmount <= PRESALE_MAX_PURCHASE,  "Can only mint 2 tokens on pre sale");

    _mintNFT(_mintAmount);
    return true;
  }


  function mintForFreeWhiteListed() public returns(bool){
    require(FREE_SALE, "pre sale not started yet");
    require(freeWhitelistedAddress[_msgSender()],  "Can only mint 1 tokens on free sale");
    _mintNFT(1);
    delete freeWhitelistedAddress[_msgSender()];
    return true;
  }


  function reserveTokens(uint256 _mintAmount) public onlyOwner() returns(bool){
    require(_mintAmount <= 100,  "Can only mint 100 tokens at a time");

    _mintNFT(_mintAmount);
    return true;
  }


  function _mintNFT(uint256 _mintAmount) internal{
    require(_mintAmount > 0, "need to mint at least 1 NFT");
    uint256 supply = totalSupply();
    require(supply + _mintAmount < MAX_SUPPLY, "max NFT limit exceeded");
      for (uint256 i = 1; i <= _mintAmount; i++) {
        _safeMint(msg.sender, supply + i);
      }
  }


  //SET BASE URL
  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  // CHANGE SALE STATE
  function startPreSale() public onlyOwner {
    PRE_SALE  = true;
  }

  function startRegularSale() public onlyOwner {
    REGULAR_SALE  = true;
    PRE_SALE  = false;
  }
  function startFreeSale() public onlyOwner {
    FREE_SALE  = true;
  }

  function changeSaleState(bool _preSale, bool _regularSale, bool _freeSale) public onlyOwner {
    PRE_SALE  = _preSale;
    REGULAR_SALE  = _regularSale;
    FREE_SALE  = _freeSale;
  }

    // SET SALE PRICE
  function setCost(uint256 _presale_price, uint256 regular_price) public onlyOwner() {
    PRESALE_PRICE =_presale_price;
    REGULAR_PRICE = regular_price;
  }


  // EDIT WHITELIST
  function addWhitelistUsers(address[] calldata _users) public onlyOwner {
    for (uint256 i = 0; i < _users.length ; i++) {
      whitelistedAddress[_users[i]] = true;
    }
  }
  
  function removeWhitelistUsers(address[] calldata _users) public onlyOwner {
    for (uint256 i = 0; i < _users.length ; i++) {
      delete whitelistedAddress[_users[i]];
    }
  }

  function addFreeWhitelistUsers(address[] calldata _users) public onlyOwner {
    for (uint256 i = 0; i < _users.length ; i++) {
      freeWhitelistedAddress[_users[i]] = true;
    }
  }
  
  function removeFreeWhitelistUsers(address[] calldata _users) public onlyOwner {
    for (uint256 i = 0; i < _users.length ; i++) {
      delete freeWhitelistedAddress[_users[i]];
    }
  }

 // SET SALE PURCHASE
  function setMaxPurchase(uint256 _presale_max_purchase, uint256 _max_purchase) public onlyOwner() {
    PRESALE_MAX_PURCHASE = _presale_max_purchase;
    MAX_PURCHASE = _max_purchase;
  }

 
  //WHITEDRAW
  function withdraw() public  onlyOwner {
    (bool success, ) = payable(owner()).call{value: address(this).balance}("");
    require(success);
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require( _exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0? string(abi.encodePacked(currentBaseURI, tokenId.toString(), ".json")): "";
  }
  
}