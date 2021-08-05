// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./ChildMintableERC721.sol";
import "./Counters.sol";

contract ChildTokenNFT is ChildMintableERC721 {

  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;
  mapping (uint256 => string) private _tokenURIs;

  constructor() ChildMintableERC721("tokenNFT0", "NFT0", 0xb5505a6d998549090530911180f38aC5130101c6) { }

  function mint(address recipient, string memory uri) public returns (uint256) {
    _tokenIds.increment();
    uint256 newItemId = _tokenIds.current();
    _mint(recipient, newItemId);
    _setTokenURI(newItemId, uri);

    return newItemId;
  }
}