// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

// @title: Sad Girls Bar
// @website: sadgirlsbar.io

//    ██████  ▄▄▄      ▓█████▄            
//  ▒██    ▒ ▒████▄    ▒██▀ ██▌           
//  ░ ▓██▄   ▒██  ▀█▄  ░██   █▌           
//    ▒   ██▒░██▄▄▄▄██ ░▓█▄   ▌           
//  ▒██████▒▒ ▓█   ▓██▒░▒████▓            
//  ▒ ▒▓▒ ▒ ░ ▒▒   ▓▒█░ ▒▒▓  ▒            
//  ░ ░▒  ░ ░  ▒   ▒▒ ░ ░ ▒  ▒            
//  ░  ░  ░    ░   ▒    ░ ░  ░            
//        ░        ░  ░   ░               
//                      ░                 
//    ▄████  ██▓ ██▀███   ██▓      ██████ 
//   ██▒ ▀█▒▓██▒▓██ ▒ ██▒▓██▒    ▒██    ▒ 
//  ▒██░▄▄▄░▒██▒▓██ ░▄█ ▒▒██░    ░ ▓██▄   
//  ░▓█  ██▓░██░▒██▀▀█▄  ▒██░      ▒   ██▒
//  ░▒▓███▀▒░██░░██▓ ▒██▒░██████▒▒██████▒▒
//   ░▒   ▒ ░▓  ░ ▒▓ ░▒▓░░ ▒░▓  ░▒ ▒▓▒ ▒ ░
//    ░   ░  ▒ ░  ░▒ ░ ▒░░ ░ ▒  ░░ ░▒  ░ ░
//  ░ ░   ░  ▒ ░  ░░   ░   ░ ░   ░  ░  ░  
//        ░  ░     ░         ░  ░      ░  
//                                        
//   ▄▄▄▄    ▄▄▄       ██▀███             
//  ▓█████▄ ▒████▄    ▓██ ▒ ██▒           
//  ▒██▒ ▄██▒██  ▀█▄  ▓██ ░▄█ ▒           
//  ▒██░█▀  ░██▄▄▄▄██ ▒██▀▀█▄             
//  ░▓█  ▀█▓ ▓█   ▓██▒░██▓ ▒██▒           
//  ░▒▓███▀▒ ▒▒   ▓▒█░░ ▒▓ ░▒▓░           
//  ▒░▒   ░   ▒   ▒▒ ░  ░▒ ░ ▒░           
//   ░    ░   ░   ▒     ░░   ░            
//   ░            ░  ░   ░                
//        ░                               

// OpenZeppelin
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC165.sol";
import "./Strings.sol";
import "./Ownable.sol";
import "./SafeMath.sol";


contract SadGirlsBar is ERC721, ERC721Enumerable, Ownable, ReentrancyGuard {
  using SafeMath for uint8;
  using SafeMath for uint256;
  using Strings for string;

  // Maximum total/giveaway tokens
  uint public constant MAX_TOKENS = 10000;
  uint public constant MAX_GIVEAWAY_TOKENS = 100;
  uint256 public constant TOKEN_PRICE = 70000000000000000; //0.07ETH

  // Emergency start/pause
  bool public isStarted = false;



  // Effectively a UUID. Only increments to avoid collisions
  // possible if we were reusing token IDs
  uint public countMintedGiveawayTokens = 0;
  uint public nextTokenId = 0;
  string private _baseTokenURI;


  /*
   * Set up the basics
   *
   * @dev It will NOT be ready to start sale immediately upon deploy
   */
  constructor(string memory baseURI) ERC721("Sad Girls Bar","SadGirlsBar") {
    setBaseURI(baseURI);
  }

  /*
   * Get the tokens owned by _owner
   */
  function tokensOfOwner(address _owner) external view returns(uint256[] memory ) {
    uint256 tokenCount = balanceOf(_owner);
    if (tokenCount == 0) {
      // Return an empty array
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

  /* Minting started here... */
  function mint(uint256 numTokens) external payable nonReentrant {
    // Check we're is online...
    require(isStarted == true, "Paused or hasn't started");
    // ...and not exceed limit
    require(totalSupply() < MAX_TOKENS, "We've got all");
    // ...and not try to get more tokens than allowed...
    require(numTokens > 0 && numTokens <= 20, "Must mint from 1 to 20 NFTs");
    // ...and not try to get more tokens than TOTALLY allowed...
    require(totalSupply().add(numTokens) <= MAX_TOKENS.sub(MAX_GIVEAWAY_TOKENS.sub(countMintedGiveawayTokens)), "Can't get more than 10000 NFTs");
     // ...and we have enough money for that.
    require(msg.value >= TOKEN_PRICE.mul(numTokens),
           "Not enough ETH for transaction");

    // mint all of these tokens
    for (uint i = 0; i < numTokens; i++) {
      nextTokenId++;
      _safeMint(msg.sender, nextTokenId);
    }
  }


  /* Allow to mint tokens for giveaways at any time (but limited count) */
  function mintGiveaway(uint256 numTokens) public onlyOwner {
    require(countMintedGiveawayTokens.add(numTokens) <= MAX_GIVEAWAY_TOKENS, "Only 100 tokens max");
    for (uint i = 0; i < numTokens; i++) {
      countMintedGiveawayTokens++;
      nextTokenId++;
      _safeMint(owner(), nextTokenId);
    }
  }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }


  function _setBaseURI(string memory baseURI) internal virtual {
    _baseTokenURI = baseURI;
  }

  function _baseURI() internal view override returns (string memory) {
    return _baseTokenURI;
  }




  // Administrative zone
  function getMintedCount() public view returns(uint) {
    return nextTokenId;
  }

  function setBaseURI(string memory baseURI) public onlyOwner {
    _setBaseURI(baseURI);
  }

  function startMint() public onlyOwner {
    isStarted = true;
  }

  function pauseMint() public onlyOwner {
    isStarted = false;
  }

  function withdrawAll() public payable onlyOwner {
    require(payable(msg.sender).send(address(this).balance));
  }

  function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
      string memory _tokenURI = super.tokenURI(tokenId);
      return bytes(_tokenURI).length > 0 ? string(abi.encodePacked(_tokenURI, ".json")) : "";
  }

}