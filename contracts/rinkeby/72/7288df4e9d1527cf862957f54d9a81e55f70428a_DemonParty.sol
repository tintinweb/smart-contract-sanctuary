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

contract DemonParty is ERC721Enumerable, Ownable {

  // timestamp of when the sale goes live
  uint256 public saleStartTimestamp;
  // timestamp of when NFTs can be revealed (if they don't sell out)
  uint256 public revealTimestamp = saleStartTimestamp + (86400 * 5);

  uint256 public immutable MAX_NFT_SUPPLY  = 100;

  uint256 public immutable MINT_PRICE = 0.1 ether;

  constructor(uint256 startTimestamp_, string memory coverURI_, string memory baseURI_) ERC721("DemonParty", "OPT") {
    saleStartTimestamp = startTimestamp_;
    coverURI = coverURI_;
    baseURI = baseURI_;
  }

  function _baseURI() internal override view returns (string memory) {
    return baseURI;
  }

  string public baseURI;
  string public coverURI;

  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    require(tokenId < MAX_NFT_SUPPLY, "token id too high");
    return string(abi.encodePacked(baseURI, Strings.toString((tokenId)), '.json'));
  }

  function mint(uint256 amount) public payable {
    require((totalSupply() + amount) <= MAX_NFT_SUPPLY, "amount exceeds max supply");

    require(msg.value == (MINT_PRICE * amount), "wrong ETH amount.");
    require(block.timestamp > saleStartTimestamp, "sale not live yet");

    for(uint i = 0; i < amount; i++) {
      _safeMint(msg.sender, totalSupply());
    }
  }

  function burn(uint256 tokenId) public {
    require(ownerOf(tokenId) == msg.sender, "not owner");
    _burn(tokenId);
  }

  /* admin functions */

  function setSaleStartTime(uint time) public onlyOwner {
    saleStartTimestamp = time;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setCoverURI(string memory _newCoverURI) public onlyOwner {
    coverURI = _newCoverURI;
  }
}