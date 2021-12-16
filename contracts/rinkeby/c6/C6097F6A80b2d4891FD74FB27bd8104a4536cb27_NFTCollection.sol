// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {ERC721Full} from './ERC721Full.sol';
import {Counters} from './Counters.sol';
import './console.sol';

contract NFTCollection is ERC721Full {
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;


  struct TokenMetadata {
    uint256 assetId;
    string metaURI;
  }

  // Event Minted
  event Minted(address owner, uint256 assetId, string tokenURI);

  // Event Minted
  event BatchMinted(address owner, uint256[] assetIds, string tokenURI);

  constructor() ERC721Full('NFTB Collection', 'NFTB') {

  }

  function mint(address to, string memory metaURI) external {
    uint256 tokenId = _mint(to, metaURI);
    emit Minted(to, tokenId, metaURI);
  }

  function batchMint(
    address to,
    string memory metaURI,
    uint256 supply
  ) external {
    require(supply > 0, 'Supply must greater than 0');

    uint256[] memory tokenIds = new uint256[](supply);

    for (uint32 i = 0; i < supply; i++) {
      uint256 tokenId = _mint(to, metaURI);
      tokenIds[i] = tokenId;
    }

    emit BatchMinted(to, tokenIds, metaURI);
  }

 

  function _mint(address to, string memory metaURI) internal returns (uint256) {
    // Mint a new PhotoNFT
    _tokenIds.increment();

    uint256 tokenId = _tokenIds.current();
    _mint(to, tokenId);
    _setTokenURI(tokenId, metaURI);

    return tokenId;
  }

  /**
   * Get tokens of owner
   */
  function tokensOfOwner(address owner) public view returns (uint256[] memory) {
    return _tokensOfOwner(owner);
  }

  /**
   * Get tokenDatas of owner
   */
  function tokenMetadataOfOwner(address owner)
    public
    view
    returns (TokenMetadata[] memory)
  {
    uint256 ownerBalance = super.balanceOf(owner);
    TokenMetadata[] memory metaDatas = new TokenMetadata[](ownerBalance);
    for (uint32 i = 0; i < ownerBalance; i++) {
      uint256 assetId = tokenOfOwnerByIndex(owner, i);
      metaDatas[i] = TokenMetadata(assetId, tokenURI(assetId));
    }
    return metaDatas;
  }

  /**
   * @dev Gets the list of token IDs of the requested owner.
   * @param owner address owning the tokens
   * @return uint256[] List of token IDs owned by the requested address
   */
  function _tokensOfOwner(address owner)
    internal
    view
    returns (uint256[] memory)
  {
    uint256 ownerBalance = super.balanceOf(owner);
    uint256[] memory assetIds = new uint256[](ownerBalance);
    for (uint32 i = 0; i < ownerBalance; i++) {
      assetIds[i] = tokenOfOwnerByIndex(owner, i);
    }
    return assetIds;
  }
}