// SPDX-License-Identifier: MIT LICENSE  

pragma solidity ^0.8.0;
import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./ERC721Upgradeable.sol";

contract Relic is 
  Initializable, 
  ERC721Upgradeable, 
  OwnableUpgradeable
{

  string public baseURI;

  /** 
   * instantiates contract
   * @param _b baseURI of metadata
   */
  function initialize(string memory _b) external initializer {
    __Ownable_init();
    __ERC721_init("Wolf Game Relic", "WRELIC");

    baseURI = _b;
  }

  function mint(uint256 tokenId, address recipient) external onlyOwner {
    _mint(recipient, tokenId);
  }

  /**
   * overrides base ERC721 implementation to return back our baseURI
   */
  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  /**
   * sets the root IPFS folder of the metadata
   * @param _b the root folder
   */
  function setBaseURI(string calldata _b) external onlyOwner {
    baseURI = _b;
  }
}