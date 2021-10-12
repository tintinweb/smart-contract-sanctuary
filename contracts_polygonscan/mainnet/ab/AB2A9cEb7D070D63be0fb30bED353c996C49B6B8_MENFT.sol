// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721URIStorage.sol";

contract MENFT is ERC721URIStorage {
  uint public counter;

  constructor() ERC721("MEMETAVERSENFT", "MENFT") {
    counter = 0;
  }

  function createNFTs (string memory tokenURI) public returns (uint) {
    uint tokenId = counter;

    _safeMint(msg.sender, tokenId);
    _setTokenURI(tokenId, tokenURI);

    counter ++;

    return tokenId;
  }

  function burn(uint tokenId) public virtual {
    require(_isApprovedOrOwner(msg.sender, tokenId), "You are not the owner or not [email protected]");
    super._burn(tokenId);
  }
}