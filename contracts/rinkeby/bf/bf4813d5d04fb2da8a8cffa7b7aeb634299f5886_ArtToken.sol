// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./nf-token-metadata.sol";
import "./Ownable.sol";

contract ArtToken is NFTokenMetadata, Ownable {

  constructor() {
    nftName = "TechnoArt";
    nftSymbol = "TAT";
  }

  function mint(address _to, uint256 _tokenId, string calldata _uri) external onlyOwner {
    super._mint(_to, _tokenId);
    super._setTokenUri(_tokenId, _uri);
  }

}