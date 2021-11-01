// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./IERC721Metadata.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./Context.sol";
import "./Strings.sol";
import "./ERC165.sol";
import "./MinterRole.sol";

contract MyLittleUzisHonoraries is ERC721Enumerable, Ownable, MinterRole {

  constructor(address[] memory addresses) ERC721("MyLittleUzisHonoraries", "MLUh") MinterRole(addresses) {
  }

  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    return tokenURIs[tokenId];
  }

  mapping (uint => string) public tokenURIs;

  function mint(address to, string memory uri) public onlyRole(MINTER_ROLE) {
    tokenURIs[totalSupply()] = uri;
    _safeMint(to, totalSupply());
  }

  /* admin functions */
  function setTokenURI(uint tokenId, string memory uri) public onlyRole(MINTER_ROLE) {
    require(tokenId < totalSupply(), "tokenId doesn't exist");
    tokenURIs[tokenId] = uri;
  }

  /**
  * @dev Withdraw ether from this contract (in case someone accidentally sends ETH to the contract)
  */
  function withdraw() onlyOwner public payable {
    uint balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}