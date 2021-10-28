// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import './ERC721Enumerable.sol';
import './Ownable.sol';
import './Strings.sol';
import './CoreFunctions.sol';
import './Metadata.sol';

contract BourbonSmokd is ERC721Enumerable, Ownable, Functions, Metadata {
  using Strings for uint256;
  
  uint256 public constant NFT_MAX = 3250;
  uint256 public constant PURCHASE_LIMIT = 10;
  uint256 public constant PURCHASE_LIMIT_PER_WALLET_DEV = 250;
  uint256 private price = 0.05 ether;

  bool public isMasterActive = false;

  string private _contractURI = '';
  string private _tokenBaseURI = '';
  string private _tokenRevealedBaseURI = '';
  
    constructor(string memory name, string memory symbol) ERC721(name, symbol) {
    }
  
  function mint(uint256 numberOfTokens) external payable {

    require(isMasterActive, 'Contract is not active');
    require(totalSupply() < NFT_MAX, 'All tokens have been minted');
    require(numberOfTokens > 0, 'You must mint more than 1 token');
    require(numberOfTokens <= PURCHASE_LIMIT, 'Cannot purchase this many tokens');
    require(totalSupply() + numberOfTokens <= NFT_MAX, 'Purchase would exceed max supply');
    require(price * numberOfTokens <= msg.value, 'ETH amount is not sufficient');

    for (uint256 i = 0; i < numberOfTokens; i++) {

      uint256 tokenId = totalSupply() + 1;

      _safeMint(msg.sender, tokenId);
    }
    
    }
    
    
    //reserve
  function reserve(address[] calldata to) external  onlyOwner {
    require(totalSupply() < NFT_MAX, 'All tokens have been minted');
    require(balanceOf(msg.sender) <= PURCHASE_LIMIT_PER_WALLET_DEV,'You cant mint anymore tokens');

    for(uint256 i = 0; i < to.length; i++) {
      uint256 tokenId = totalSupply() + 1;

      _safeMint(to[i], tokenId);
    }
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
    
    address Address1 = 0xf5099d14CB07f280c2D10524Cf591abb3822a8c3; //team1
    address Address2 = 0x3c7E76135C1E5DB500Ef9b5e90496F0c07fe9Cc6; //team2
    address Address3 = 0xCFf5c9D1a5445cddC8D8471f7643dA3dAbd0D99d; //team3
    address Address4 = 0x3B5621aa1B90abDf0DC824a2bf3402BcCaf2cD4a; //team4
    address Address5 = 0xEcc03efB7C0A7BD09A5cC7e954Ac42E8f949A0B5; //niftylabs

    //balances
    function withdraw() onlyOwner public {
        uint balance = address(this).balance;
        payable(Address1).transfer(balance*245/800);
        payable(Address2).transfer(balance*175/800);       
        payable(Address3).transfer(balance*35/200);      
        payable(Address4).transfer(balance*10/100);      
        payable(Address5).transfer(balance*20/100);
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

    /// @dev Convert string to bytes so we can check if it's empty or not.
    string memory revealedBaseURI = _tokenRevealedBaseURI;
    return bytes(revealedBaseURI).length > 0 ?
      string(abi.encodePacked(revealedBaseURI, tokenId.toString())) :
      _tokenBaseURI;
  }
}