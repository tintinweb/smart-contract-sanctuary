// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./SafeMath.sol";
import "./ERC721Enumerable.sol";

/**
 * @title BB1
 * BB1 - A contract for non-fungible Bodacious Bears Generation 1.
 */
contract BB1 is ERC721Enumerable, Ownable {
  using SafeMath for uint256;
  using Counters for Counters.Counter;

  /**
    * We rely on the OZ Counter util to keep track of the next available ID.
    * We track the nextTokenId instead of the currentTokenId to save users on gas costs. 
    * Read more about it here: https://shiny.mirror.xyz/OUampBbIz9ebEicfGnQf5At_ReMHlZy0tB4glb9xQ0E
    */ 
  Counters.Counter private _nextTokenId;

  uint256 private _price = 0.06 ether;
  bool public _paused = true;
  address proxyRegistryAddress;

  uint public constant MAX_SUPPLY = 10000;
  uint public constant MAX_PER_MINT = 5;

  constructor() ERC721("Bodacious Bear Gen 1", "BB1") {
    _nextTokenId.increment();
  }

  function _mintSingleNFT(address _to) private {
      uint256 currentTokenId = _nextTokenId.current();
      _nextTokenId.increment();
      _safeMint(_to, currentTokenId);
  }

  /**
    * @dev Mints a token to an address with a tokenURI.
    * @param _to address of the future owner of the token
    */
  function mintTo(address _to) public onlyOwner {
      _mintSingleNFT(_to);
  }

    /**
    * @dev Mints a token to an address with a tokenURI, for price
    * @param _to address of the future owner of the token
    * @param _quantity quantity to be minted
    */
  function mint(address _to, uint256 _quantity) public virtual payable {
      uint256 totalMinted = totalSupply();
      
      require(
        !_paused, "Sale paused"
      );

      require(
        totalMinted.add(_quantity) <= MAX_SUPPLY, "Not enough NFTs"
      );

      require(
        _quantity > 0 && _quantity <= MAX_PER_MINT, "Cannot mint specified number of NFTs."
      );
      
      require(
        msg.value >= _price.mul(_quantity), "Not enough ether to purchase NFTs."
      );
      
      for (uint256 i = 0; i < _quantity; i++) {
        _mintSingleNFT(_to);
      }
  }
    
  function tokensOfOwner(address _owner) external view returns (uint256[] memory) {
    uint256 tokenCount = balanceOf(_owner);
    uint256[] memory tokensId = new uint256[](tokenCount);
    for (uint256 i = 0; i < tokenCount; i++) {
      tokensId[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokensId;
  }

  function getPrice() public view returns (uint256){
    return _price;
  }

  // As a safety precaution in case of major eth fluctuation
  function setPrice(uint256 _newPrice) public onlyOwner() {
    _price = _newPrice;
  }

  function pause(bool val) public onlyOwner {
    _paused = val;
  }

  /**
      @dev Returns the total tokens minted so far.
      1 is always subtracted from the Counter since it tracks the next available tokenId.
    */
  function totalSupply() override public view returns (uint256) {
    return _nextTokenId.current() - 1;
  }

  function baseTokenURI() public pure returns (string memory) {
    return "https://api.bodaciousbears.com/bb1/";
  }

  function tokenURI(uint256 _tokenId) override public pure returns (string memory) {
    return string(abi.encodePacked(baseTokenURI(), Strings.toString(_tokenId)));
  }

}