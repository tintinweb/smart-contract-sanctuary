// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.6;

import "./ERC721.sol";
import "./Ownable.sol";

contract Alphabet is ERC721, Ownable {
  /*///////////////////////////////////////////////////////////////
    METADATA
  //////////////////////////////////////////////////////////////*/

  string public baseURI;

  function tokenURI(uint256 id) public view virtual override returns (string memory) {
    return string(abi.encodePacked(baseURI, uint2str(id), ".json"));
  }

  /*///////////////////////////////////////////////////////////////
    CONSTRUCTOR
  //////////////////////////////////////////////////////////////*/

  constructor() ERC721("Alphabet", "ALPHA") {
    baseURI="ipfs://QmWmFB7VvroiFGBpxkATphs77vH7aFeuBBTvR8ay9R7LE5/";
  }

  uint256 public immutable NFT_PRICE = 0.001 ether;
  uint256 public MAX_SUPPLY = 84;

  function mint(uint amount) public payable {
    require(msg.value == (amount * NFT_PRICE), "wrong ETH amount");
    require(owners.length < MAX_SUPPLY, "ALREADY_MINTED");
    for(uint i = 0; i < amount; i++) {
      _mint(msg.sender, owners.length);
    }
  }

  function burn(uint id) public {
    _burn(id);
  }

  /// @dev convert int to string
  ///        source: https://stackoverflow.com/a/65707309
  function uint2str( uint256 _i) internal pure returns (string memory str) {
    if (_i == 0)
      {
        return "0";
      }
      uint256 j = _i;
      uint256 length;
      while (j != 0)
        {
          length++;
          j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint256 k = length;
        j = _i;
        while (j != 0)
          {
            bstr[--k] = bytes1(uint8(48 + j % 10));
            j /= 10;
          }
          str = string(bstr);
  }

  // ADMIN FUNCTIONS //
  function setBaseUri(string memory uri) public onlyOwner {
    baseURI = uri;
  }
}