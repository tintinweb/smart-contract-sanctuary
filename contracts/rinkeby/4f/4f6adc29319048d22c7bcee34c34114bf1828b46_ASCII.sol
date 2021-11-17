// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import './ERC721Enumerable.sol';
import './Ownable.sol';
import './Strings.sol';
import './ASCIIFunctions.sol';
import './Metadata.sol';

contract ASCII is ERC721Enumerable, Ownable, Functions, Metadata {
  using Strings for uint256;
  
  uint256 public constant MAX = 8910;
  uint256 public constant PURCHASE_LIMIT_FREE = 1;
  uint256 public constant PURCHASE_LIMIT_PAID = 4;
  uint256 private price = 0.01 ether;

  bool public isMasterActive = false;

  string private _contractURI = '';
  string private _tokenBaseURI = '';
  string private _tokenRevealedBaseURI = '';

    mapping(address => uint256) private _freeMintTotal;
    mapping(address => uint256) private _paidMintTotal;

  address Address1 = 0xeDF821a5dB36B2267895E539927E824d5a86A87f; //team
  address Address2 = 0xEcc03efB7C0A7BD09A5cC7e954Ac42E8f949A0B5; //nl
  
  constructor(string memory name, string memory symbol) ERC721(name, symbol) {
  }

  function freeMintTotal(address owner) external view override returns (uint256){
    require(owner != address(0), 'Zero address');
    return _freeMintTotal[owner];
  }

  function paidMintTotal(address owner) external view override returns (uint256){
    require(owner != address(0), 'Zero address');
    return _paidMintTotal[owner];
  }
  
  function mintFreeAscii() external  {
    require(isMasterActive, 'Contract not active');
    require(totalSupply() < MAX, 'All tokens minted');
    require(_freeMintTotal[msg.sender] + 1 <= PURCHASE_LIMIT_FREE,'Already maxed out');

      uint256 tokenId = totalSupply() + 1;
       _freeMintTotal[msg.sender] += 1;
      _safeMint(msg.sender, tokenId);
  }

  function mintPaidAscii_max4_01EthEach(uint256 hash_ASC) external payable  {

    require(isMasterActive, 'Contract not active');
    require(totalSupply() < MAX, 'All tokens minted');
    require(hash_ASC <= PURCHASE_LIMIT_PAID, 'Mint less');
    require(_paidMintTotal[msg.sender] + hash_ASC <= PURCHASE_LIMIT_PAID,'Already maxed out');
    require(totalSupply() + hash_ASC <= MAX, 'Would exceed max supply');

    for (uint256 i = 0; i < hash_ASC; i++) {
      uint256 tokenId = totalSupply() + 1;
      _paidMintTotal[msg.sender] += 1;
      _safeMint(msg.sender, tokenId);
    }
    }

  function ownerMintToWallet(address _0x) external onlyOwner  {
    require(isMasterActive, 'Contract not active');
    require(totalSupply() < MAX, 'All tokens minted');
      uint256 tokenId = totalSupply() + 1;
      _safeMint(_0x, tokenId);
  }

  function MasterActive(bool _isMasterActive) external override onlyOwner {
    isMasterActive = _isMasterActive;
  }
  
    function setPrice(uint256 _newPrice) public onlyOwner() {
        price = _newPrice;
    }
    
    function getPrice() public view returns (uint256){
        return price;
    }

    function withdraw() onlyOwner public {
        uint balance = address(this).balance;      
        payable(Address1).transfer(balance*95/100);      
        payable(Address2).transfer(balance*5/100);      
        payable(msg.sender).transfer(address(this).balance);
    }

  function setContractURI(string calldata URI) external override onlyOwner {
    _contractURI = URI;
  }

  function setBaseURI(string calldata URI) external override onlyOwner {
    _tokenBaseURI = URI;
  }

  function setRevealedBaseURI(string calldata revealedBaseURI) external override onlyOwner {
    _tokenRevealedBaseURI = revealedBaseURI;
  }

  function contractURI() public view override returns (string memory) {
    return _contractURI;
  }

  function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
    require(_exists(tokenId), 'Token does not exist');
    string memory revealedBaseURI = _tokenRevealedBaseURI;
    return bytes(revealedBaseURI).length > 0 ?
      string(abi.encodePacked(revealedBaseURI, tokenId.toString())) :
      _tokenBaseURI;
  }
}