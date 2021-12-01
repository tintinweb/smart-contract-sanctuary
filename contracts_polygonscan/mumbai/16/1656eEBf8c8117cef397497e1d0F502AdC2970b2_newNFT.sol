// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;
 
import "./nf-token-metadata.sol";
import "./ownable.sol";
 
contract newNFT is NFTokenMetadata, Ownable {
 
  constructor() {
    nftName = "NIKO #001";
    nftSymbol = "NIKO1";
  }
 
  function mint(address _to, uint256 _tokenId, string calldata _uri) external onlyOwner {
    super._mint(_to, _tokenId);
    super._setTokenUri(_tokenId, _uri);
  }
 
}