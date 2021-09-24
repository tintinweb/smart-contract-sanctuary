// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./nf-token-metadata.sol";
import "./ownable.sol";
 
contract NFTGallery is NFTokenMetadata, Ownable {
 
  constructor() {
    nftName = "NFTGallery";
    nftSymbol = "NFTG";
  }
  uint256 public _tokenId = 1;


  function mint(address _to , string calldata _uri) external onlyOwner {
    super._mint(_to, _tokenId);
    super._setTokenUri(_tokenId, _uri);
     _tokenId ++ ;
    
    
  }
 }