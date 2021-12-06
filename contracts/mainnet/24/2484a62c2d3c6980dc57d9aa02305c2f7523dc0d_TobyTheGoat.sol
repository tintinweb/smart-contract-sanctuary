// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Openzeppelin
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";

// ___          ___         __             
//  |  _  |_     | |_   _  /__  _   _. _|_ 
//  | (_) |_) \/ | | | (/_ \_| (_) (_|  |_ 
//            /
// Toby The Goat (TTG)
// Website: https://tobythegoat.io
//     (_(
//     /_/'_____/)
//     "  |      |
//        |""""""|

contract TobyTheGoat is ERC721, ERC721Enumerable, Ownable, ReentrancyGuard {
  using SafeMath for uint8;
  using SafeMath for uint256;
  // total tokens
  uint256 public constant MAX_TOKENS = 9999;
  // maximum tokens for giveaways
  uint256 public constant MAX_GIVEAWAY_TOKENS = 200;
  uint256 public constant TOKEN_PRICE = 60000000000000000; //0.06ETH
  // enables or disables the public sale
  bool public isStarted = false;
  // keeps track of tokens minted for giveaways
  uint256 public countMintedGiveawayTokens = 0;
  // keeps track of tokens minted
  uint256 public countMintedTokens = 0;
  string private _baseTokenURI;
  // random nonce/seed
  uint256 internal nonce = 0;
  // used to randomize the mint
  uint256[MAX_TOKENS] internal tokenIdx;
  // Mapping owner address to token count
  mapping(address => uint256) private _balances;

  constructor(string memory baseURI) ERC721("Toby The Goat", "TTG") {
    setBaseURI(baseURI);
  }

  // get tokens owned by the provided address
  function tokensOfOwner(address _owner) external view returns (uint256[] memory) {
    uint256 tokenCount = balanceOf(_owner);
    if (tokenCount == 0) {
      // return an empty array
      return new uint256[](0);
    } else {
      uint256[] memory result = new uint256[](tokenCount);
      uint256 index;
      for (index = 0; index < tokenCount; index++) {
        result[index] = tokenOfOwnerByIndex(_owner, index);
      }
      return result;
    }
  }

  // generates a random index for minting
  function randomIndex() internal returns (uint256) {
    uint256 availableTokens = MAX_TOKENS - totalSupply();
    uint256 rnd = uint256(keccak256(abi.encodePacked(nonce, msg.sender, block.difficulty, block.timestamp))) % availableTokens;
    uint256 value = 0;

    if (tokenIdx[rnd] != 0) {
      value = tokenIdx[rnd];
    } else {
      value = rnd;
    }

    if (tokenIdx[availableTokens - 1] == 0) {
      tokenIdx[rnd] = availableTokens - 1;
    } else {
      tokenIdx[rnd] = tokenIdx[availableTokens - 1];
    }
    nonce++;
    return value.add(1);
  }

  // public method for minting tokens
  function mint(uint256 numTokens) external payable nonReentrant {
    // check if the public sale is active
    require(isStarted, "Minting is paused or has not started");

    // check if there are tokens available
    require(totalSupply() < MAX_TOKENS, "All tokens have been minted");

    // check if the number of requested tokens is between the limits
    require(numTokens > 0 && numTokens <= 10, "The number of tokens must be between 1 and 10");

    // check if the number of requested tokens does not surpass the limit of tokens
    require(totalSupply().add(numTokens) <= MAX_TOKENS.sub(MAX_GIVEAWAY_TOKENS.sub(countMintedGiveawayTokens)), "The number of requested tokens would surpass the limit of tokens");

    // check if enough eth has been provided for the minting
    require(msg.value >= TOKEN_PRICE.mul(numTokens), "Not enough ETH for transaction");

    // mint the tokens with random indexes
    for (uint256 i = 0; i < numTokens; i++) {
      countMintedTokens++;
      mintWithRandomTokenId(msg.sender);
    }
  }

  // method used for minting tokens for giveaways
  function mintGiveaway(uint256 numTokens) public onlyOwner {
    require(countMintedGiveawayTokens.add(numTokens) <= MAX_GIVEAWAY_TOKENS, "200 tokens max");
    for (uint256 i = 0; i < numTokens; i++) {
      countMintedGiveawayTokens++;
      mintWithRandomTokenId(owner());
    }
  }

  // mints tokens with random indexes
  function mintWithRandomTokenId(address _to) private {
    uint256 _tokenID = randomIndex();
    _safeMint(_to, _tokenID);
  }

  function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  // returns the URI of a token that is minted
  function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
    string memory _tokenURI = super.tokenURI(tokenId);
    return bytes(_tokenURI).length > 0 ? string(abi.encodePacked(_tokenURI, ".json")) : "";
  }

  function _setBaseURI(string memory baseURI) internal virtual {
    _baseTokenURI = baseURI;
  }

  function _baseURI() internal view override returns (string memory) {
    return _baseTokenURI;
  }

  // Administrative zone
  function setBaseURI(string memory baseURI) public onlyOwner {
    _setBaseURI(baseURI);
  }

  function startMint() public onlyOwner {
    isStarted = true;
  }

  function pauseMint() public onlyOwner {
    isStarted = false;
  }

  function withdraw() public payable onlyOwner {
    require(payable(msg.sender).send(address(this).balance));
  }
}