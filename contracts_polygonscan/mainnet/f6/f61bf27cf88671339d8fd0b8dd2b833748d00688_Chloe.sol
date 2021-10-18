// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./ERC721MetadataEnumerable.sol";
import "./Freezable.sol";
import "./Describable.sol";

contract Chloe is
  ERC721MetadataEnumerable,
  Freezable,
  Describable
{

  constructor(string memory name, string memory symbol, string memory description, address to, string memory uri) public {
    nftName = name;
    nftSymbol = symbol;
    _setupDescription(description);
    _freeze(msg.sender, false);
    if (to != address(0)) {
      _freeze(to, false);
      mint(to, 1, uri);
    }
  }

  function mint(address to, uint256 tokenId, string memory uri) public onlyOwner {
    super._mint(to, tokenId);
    super._setTokenUri(tokenId, uri);
  }

  function burn(uint256 tokenId) external onlyOwner {
    super._burn(tokenId);
  }

  function _beforeTokenTransfer(address from, address to, uint256) internal override whenTransfer(from, to) {
  }

  function unfreezeAndMint(address recipient, uint256 tokenId, string calldata uri) public onlyOwner {
      unfreeze(recipient);
      mint(recipient, tokenId, uri);
  }

  function unfreezeAndTransfer(address recipient) public onlyOwner {
      unfreeze(recipient);
      super._transfer(recipient, 1);
  }
}