// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './ERC721Enumerable.sol';
import './Ownable.sol';
import './Strings.sol';
import './Functions.sol';
import './Metadata.sol';

contract NonFun is ERC721Enumerable, Ownable, Functions, Metadata {
  
  using Strings for uint256;

  uint256 public constant MAIN_DROP = 9000;      
  uint256 public constant MAIN_PRICE = 0.001 ether;

  uint256 public totalBurnSupply;
  
  string private _contractURI = '';
  string private _tokenBaseURI = '';
  string private _tokenRevealedBaseURI = '';
  
  event Burn(
        uint256 token1,
        uint256 token2,
        uint256 newTokenId1,
        uint256 newTokenId2
        );
  
  
  constructor(string memory name, string memory symbol) ERC721(name, symbol) {

  }
  
  function mint(uint256 numberOfTokens) public payable {
   uint256 s = totalSupply();
    for (uint256 i = 0; i < numberOfTokens; i++) {
      _safeMint(msg.sender, s + i, ""); // Only 5.
    }
    delete s;
    }
  
  function withdraw() external override onlyOwner {
    uint256 balance = address(this).balance;
    payable(msg.sender).transfer(balance);
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
    
   function burn(uint256 token1, uint256 token2) public  {
      require(_isApprovedOrOwner(_msgSender(), token1) 
      && _isApprovedOrOwner(_msgSender(), token2), 
      "Caller is not owner nor approved");
      // burn
      _burn(token1);
      _burn(token2);

      // mint new token
      uint256 newTokenId1 = MAIN_DROP + totalBurnSupply;
      _safeMint(msg.sender, newTokenId1);
      totalBurnSupply += 1;
      // mint second token
      uint256 newTokenId2 = MAIN_DROP + totalBurnSupply;
      _safeMint(msg.sender, newTokenId2);
      totalBurnSupply += 1;

      // fire event in logs
      emit Burn(token1, token2, newTokenId1, newTokenId2);
    }
  

}