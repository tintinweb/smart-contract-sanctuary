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

  constructor(address[] memory minters, string memory _baseURI, address[] memory receivers) ERC721("MyLittleUzisHonoraries", "MLUh") MinterRole(minters) {
    baseURI = _baseURI;
    for(uint i = 0; i < receivers.length; i++) {
      mint(receivers[i], string(abi.encodePacked(baseURI, Strings.toString(i), ".json")));
    }
  }

  string public baseURI;

  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    require(tokenId < totalSupply(), "token doesn't exist");
    return string(abi.encodePacked(baseURI, Strings.toString(tokenId), ".json"));
  }

  mapping (uint => string) public tokenURIs;

  function mint(address to, string memory uri) public onlyRole(MINTER_ROLE) {
    tokenURIs[totalSupply()] = uri;
    _safeMint(to, totalSupply());
  }

  /* admin functions */
  function setBaseURI(string memory uri) public onlyRole(MINTER_ROLE) {
    baseURI = uri;
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