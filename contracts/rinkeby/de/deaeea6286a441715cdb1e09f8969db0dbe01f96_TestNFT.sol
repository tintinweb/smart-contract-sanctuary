// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract TestNFT is ERC721Enumerable, Ownable {
  uint256 public constant COLLECTION_SIZE = 5;
  uint256 public constant PRICE = 50000000000000000;
  uint256 public constant MINT_LIMIT = 1;

  bool public isSaleActive;
  string public currentBaseTokenURI;

  constructor() ERC721("TestyyyNFT", "TNFT") {}

  function mintTimeMachine(uint256 units) public payable {
    uint256 mintIndex = totalSupply();

    require(isSaleActive, "The time machine is not active");
    require(units <= MINT_LIMIT, "You can only buy 10 time machines");
    require(mintIndex + units <= COLLECTION_SIZE, "The units requested exceed the collection size");
    require(units * PRICE <= msg.value, "The transaction value is not correct");

    uint256 i;
    for (i = 0; i < units; i++) {
      uint256 timemachineId = mintIndex + i;

      if (timemachineId < COLLECTION_SIZE) {
        _safeMint(msg.sender, timemachineId);
      }
    }
  }

  function baseTokenURI() public view returns (string memory) {
    return currentBaseTokenURI;
  }

  function tokenURI(uint256 tokenId) override public view returns (string memory) {
    require(_exists(tokenId), "URI query for a time machine that doesnt exist");

    return string(abi.encodePacked(baseTokenURI(), Strings.toString(tokenId), ".json"));
  }

  function walletOfOwner(address walletAddress) public view returns (uint256[] memory) {
    uint256 tokenCount = balanceOf(walletAddress);
    uint256[] memory tokenIds = new uint256[](tokenCount);

    uint256 i;
    for (i = 0; i < tokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(walletAddress, i);
    }

    return tokenIds;
  }

  function toggleSaleState() public onlyOwner {
    isSaleActive = !isSaleActive;
  }

  function setBaseTokenURI(string memory URI) public onlyOwner {
    currentBaseTokenURI = URI;
  }

  function withdraw() public onlyOwner {
    uint256 balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }

  function reserve(uint256 units) public onlyOwner {
    uint256 mintIndex = totalSupply();
    uint256 reserveLimit = 1;

    require(units <= reserveLimit, "The maximum reserve is 1");
    require(mintIndex + units <= COLLECTION_SIZE, "The reserve requested exceeds the collection size");

    uint256 i;
    for (i = 0; i < units; i++) {
      uint256 timemachineId = mintIndex + i;

      if (timemachineId < COLLECTION_SIZE) {
        _safeMint(msg.sender, timemachineId);
      }
    }
  }
}