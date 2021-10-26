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

contract BullishTerriersTest1 is ERC721Enumerable, Ownable {

  // timestamp of when the sale goes live
  uint256 public saleStartTimestamp;
  // timestamp of when NFTs can be revealed (if they don't sell out)
  uint256 public revealTimestamp = saleStartTimestamp + (86400 * 5);

  // randomization values
  uint256 public startingIndexBlock;
  uint256 public startingIndex;

  // uint256 public immutable MAX_PER_ADDRESS = 2;
  uint256 public immutable MAX_NFT_SUPPLY  = 4444;

  uint256 public immutable MINT_PRICE = 0.004 ether;

  constructor(uint256 startTimestamp_, string memory coverURI_, string memory baseURI_) ERC721("BullishTerriersTest1", "BT1") {
    saleStartTimestamp = startTimestamp_;
    coverURI = coverURI_;
    baseURI = baseURI_;
  }

  // track who has minted to cap mints at 2 per address
  mapping(address => uint256) minters;

  function _baseURI() internal override view returns (string memory) {
    return baseURI;
  }

  string public baseURI;
  string public coverURI;

  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    require(tokenId < MAX_NFT_SUPPLY, "token id too high");
    if(startingIndex == 0) {
      return coverURI;
    }
    return string(abi.encodePacked(baseURI, Strings.toString((tokenId + startingIndex) % MAX_NFT_SUPPLY), '.json'));
  }

  function mint(uint256 amount) public payable {
    address minter = msg.sender;
    // require((minters[minter] + amount) <= MAX_PER_ADDRESS, "amount exceeds max of 2 per address");
    require((totalSupply() + amount) <= MAX_NFT_SUPPLY, "amount exceeds max supply");
    // uint256 expectedMintPrice = MINT_PRICE * amount;
    // require(msg.value == (MINT_PRICE * amount), "wrong ETH amount. should be " + expectedMintPrice.toString());
    require(msg.value == (MINT_PRICE * amount), "wrong ETH amount.");
    require(block.timestamp > saleStartTimestamp, "sale not live yet");

    for(uint i = 0; i < amount; i++) {
      uint256 mintIndex = totalSupply();
      _safeMint(msg.sender, mintIndex);
    }

    minters[minter] += amount;

    /**
     * Source of randomness. Theoretical miner withhold manipulation possible but should be sufficient in a pragmatic sense
     */
    if (startingIndexBlock == 0 && (totalSupply() == MAX_NFT_SUPPLY || block.timestamp >= revealTimestamp)) {
      startingIndexBlock = block.number;
    }
  }

  /* randomization */
  /**
  * @dev Finalize starting index
  */
  function finalizeStartingIndex() public {
    require(startingIndex == 0, "Starting index is already set");
    require(startingIndexBlock != 0, "Starting index block must be set");

    startingIndex = uint(blockhash(startingIndexBlock)) % MAX_NFT_SUPPLY;
    // Just a sanity case in the worst case if this function is called late (EVM only stores last 256 block hashes)
    if ((block.number - startingIndexBlock) > 255) {
      startingIndex = uint(blockhash(block.number-1)) % MAX_NFT_SUPPLY;
    }
    // Prevent default sequence
    if (startingIndex == 0) {
      startingIndex = startingIndex + 1;
    }
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

  /**
  * @dev Withdraw ether from this contract (in case someone accidentally sends ETH to the contract)
  */
  function withdraw() onlyOwner public payable {
    uint balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }
}