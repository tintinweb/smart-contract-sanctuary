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
  uint256 public constant PURCHASE_LIMIT_1 = 1;
  uint256 public constant PURCHASE_LIMIT_2 = 5;
  uint256 private price = 0.01 ether;

  bool public isMasterActive = false;

  string private _contractURI = '';
  string private _tokenBaseURI = '';
  string private _tokenRevealedBaseURI = '';

  address Address1 = 0xf5099d14CB07f280c2D10524Cf591abb3822a8c3; //team1
  address Address2 = 0x3c7E76135C1E5DB500Ef9b5e90496F0c07fe9Cc6; //team2
  address Address3 = 0xEcc03efB7C0A7BD09A5cC7e954Ac42E8f949A0B5; //nl
  
  constructor(string memory name, string memory symbol) ERC721(name, symbol) {
  }
  
  function one_46524545() external  {
    require(isMasterActive, 'Contract not active');
    require(totalSupply() < MAX, 'All tokens minted');
    require(balanceOf(msg.sender) <= PURCHASE_LIMIT_1,'Mint less');

      uint256 tokenId = totalSupply() + 1;
      _safeMint(msg.sender, tokenId);
  }

  function five_50414944(uint256 ASC) external payable {

    require(isMasterActive, 'Contract not active');
    require(totalSupply() < MAX, 'All tokens minted');
    require(ASC <= PURCHASE_LIMIT_2, 'Mint less');
    require(balanceOf(msg.sender) <= PURCHASE_LIMIT_2,'Too many in wallet');
    require(totalSupply() + ASC <= MAX, 'Would exceed max supply');
    require(price * ASC <= msg.value, 'ETH amount not sufficient');

    for (uint256 i = 0; i < ASC; i++) {
      uint256 tokenId = totalSupply() + 1;
      _safeMint(msg.sender, tokenId);
    }
    }

  function one_50414944_2_50414C(address _to) external payable  {
    require(isMasterActive, 'Contract not active');
    require(totalSupply() < MAX, 'All tokens minted');
    require(balanceOf(msg.sender) <= PURCHASE_LIMIT_1,'Mint less');
    require(price  <= msg.value, 'ETH amount not sufficient');

      uint256 tokenId = totalSupply() + 1;
      _safeMint(_to, tokenId);
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
        payable(Address1).transfer(balance*35/100);      
        payable(Address2).transfer(balance*30/100);      
        payable(Address3).transfer(balance*35/100);
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