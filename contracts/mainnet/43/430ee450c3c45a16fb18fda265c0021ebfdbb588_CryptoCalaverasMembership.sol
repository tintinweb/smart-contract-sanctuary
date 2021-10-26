// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import './ERC721Enumerable.sol';
import './Ownable.sol';
import './Strings.sol';
import './CoreFunctions.sol';
import './Metadata.sol';

contract CryptoCalaverasMembership is ERC721Enumerable, Ownable, Functions, Metadata {
  using Strings for uint256;
  
  uint256 public constant NFT_MAX = 3333;
  uint256 public constant PURCHASE_LIMIT = 10;
  uint256 public constant PURCHASE_LIMIT_PER_WALLET_DEV = 50;
  uint256 private price = 0.04 ether;

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
    
    address Address1 = 0xB304bf6bAaE65Ac9A3B1CdBB4E48e5589a3ff9A2; //team1
    address Address2 = 0xCAa63F2f8571Eae0163C0C26ECcF2872589eA170; //team2
    address Address3 = 0xF4A12bC4596E1c3e19D512F76325B52D72D375CF; //team3
    address Address4 = 0xdA00A06Ab3BbD3544B79C1350C463CAb9f196880; //team4
    address Address5 = 0x65a112b4604eb4B946D14E8EFbcc39f6968F49bE; //team5
    address Address6 = 0x96C2A8e9437dE19215121b7137650eC6A032DF5B; //team6
    address Address7 = 0x01c3f58FaaEbf4B9a3eaD760Fb8A7bb0C3168467; //team7
    address Address8 = 0x75e06a34c1Ef068fC43ad56A1a5193f3778bF0B2; //team8
    address Address9 = 0xf38c60143b655A5d7b68B49C189Da7CB2b0604A1; //team9
    address Address10 = 0xa3f070BAEf828f712f38c360221B5250284891D7; //team10
    address Address11 = 0xEcc03efB7C0A7BD09A5cC7e954Ac42E8f949A0B5; //niftylabs
    address Address12 = 0xdFD02b83062edb018FfF3dA3C3151bFb2681E3aE; //treasury

    function withdraw() onlyOwner public {
        uint balance = address(this).balance;
        payable(Address1).transfer(balance*791/10000);
        payable(Address2).transfer(balance*791/10000);       
        payable(Address3).transfer(balance*791/10000);      
        payable(Address4).transfer(balance*791/10000);      
        payable(Address5).transfer(balance*791/10000);
        payable(Address6).transfer(balance*791/10000);
        payable(Address7).transfer(balance*791/10000);
        payable(Address8).transfer(balance*791/10000);
        payable(Address9).transfer(balance*791/10000);       
        payable(Address10).transfer(balance*791/10000);      
        payable(Address11).transfer(balance*1590/10000);      
        payable(Address12).transfer(balance*500/10000);
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