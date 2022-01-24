// contracts/SameSameNFT.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";

contract SameSameNFT is ERC721, ReentrancyGuard, Ownable {
  uint256 private tokenCount = 1;
  mapping(uint256 => string) private tokenUris;

  function append(string memory a, string memory b, string memory c) internal pure returns (string memory) {
    return string(abi.encodePacked(a, b, c));
  }

  constructor() ERC721("SameSameButDiff", "SSBD") {
    return;
  }

  function mintOne(string calldata tokenPath) payable public {
    require(msg.value == 0.0069 * 10**18, "Minting costs 0.0069 ETH");

    _mint(msg.sender, tokenCount);

    tokenUris[tokenCount] = tokenPath;
    tokenCount += 1;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    string storage info = tokenUris[tokenId];
    if (bytes(info).length == 0) { 
      return '';
    }
    return append("https://ipfs.io/ipfs/", tokenUris[tokenId], "/metadata.json");
  }
}