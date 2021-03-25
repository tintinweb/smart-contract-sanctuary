// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";
//import "./ERC721URIStorage.sol";

contract primo is ERC721, Ownable
{
  using Counters for Counters.Counter;
  using Strings for uint256;        //storage

  Counters.Counter private _counter;
  mapping(string => uint8) public hashes;
  // Optional mapping for token URIs
  mapping (uint256 => string) private _tokenURIs;
  //address private _owner;


  /* modifier to add to function that should only be callable by contract owner */
  /*
  modifier onlyBy(address _account)
  {
      require(msg.sender == _account);
      _;
  }
    */

  constructor() ERC721("primo", "PRM") {
        //_owner = msg.sender;
  }

  /**
   * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   */

  function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
      require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
      _tokenURIs[tokenId] = _tokenURI;
  }


  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
      require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

      string memory _tokenURI = _tokenURIs[tokenId];
      string memory base = _baseURI();

      // If there is no base URI, return the token URI.
      if (bytes(base).length == 0) {
          return _tokenURI;
      }
      // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
      if (bytes(_tokenURI).length > 0) {
          return string(abi.encodePacked(base, _tokenURI));
      }

      return tokenURI(tokenId);
  }

    /**
     * @dev Returns the address of the current owner.
     */
     /*
    function owner() internal view virtual returns (address) {
        return _owner;
    }
    */

   function mintPRM(address recipient, string memory hash, string memory metadata) onlyOwner public returns(uint256) {
    //require(owner() == msg.sender, "Caller is not the owner");
    require(hashes[hash] != 1, "Hash has already been used!");
    hashes[hash] = 1;
    _counter.increment();
    uint256 newPRMId = _counter.current();
    _mint(recipient, newPRMId);
    _setTokenURI(newPRMId, metadata);
    return newPRMId;
  }
}