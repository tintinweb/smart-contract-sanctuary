// SPDX-License-Identifier: MIT LICENSE  

pragma solidity ^0.8.0;
import "./Ownable.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721Enumerable.sol";
import "./WOOL.sol";

contract Farmer is ERC721Enumerable, Ownable, Pausable, ReentrancyGuard {

  // mint price
  uint256 public constant MINT_PRICE = 10000 ether;
  // max number of tokens that can be minted - 20000 in production
  uint256 public immutable MAX_TOKENS;
  // number of tokens have been minted so far
  uint16 public minted;

  // reference to $WOOL for burning on mint
  WOOL public wool;
  // root IPFS folder for metadata / images
  string public baseURI;

  /** 
   * instantiates contract
   * @param _b root IPFS folder
   * @param _wool reference to $WOOL token
   * @param _maxTokens number of tokens available to mint
   */
  constructor(string memory _b, address _wool, uint256 _maxTokens) ERC721("Farmer", 'FARMER') { 
    baseURI = _b;
    wool = WOOL(_wool);
    MAX_TOKENS = _maxTokens;
    _pause();
  }

  /** EXTERNAL */

  /**
   * mints Farmer tokens for WOOL
   * @param amount the number of tokens to mint
   */
  function mint(uint256 amount) external nonReentrant whenNotPaused {
    require(minted + amount <= MAX_TOKENS, "All tokens minted");
    require(amount > 0 && amount <= 2, "Invalid mint amount");

    wool.burn(_msgSender(), MINT_PRICE * amount); // will fail if the minter doesn't have enough

    for (uint i = 0; i < amount; i++) {
      minted++;
      _safeMint(_msgSender(), minted);
    }
  }

  /** INTERNAL */

  /**
   * overrides base ERC721 implementation to return back our baseURI
   */
  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  /** ADMIN */

  /**
   * enables owner to pause / unpause minting
   */
  function setPaused(bool _paused) external onlyOwner {
    if (_paused) _pause();
    else _unpause();
  }

  /**
   * sets the root IPFS folder of the metadata
   * @param _b the root folder
   */
  function setBaseURI(string calldata _b) external onlyOwner {
    baseURI = _b;
  }
}