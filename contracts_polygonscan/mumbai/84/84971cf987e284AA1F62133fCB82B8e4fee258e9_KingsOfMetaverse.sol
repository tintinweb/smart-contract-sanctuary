// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "./ERC721URIStorage.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./ERC1155Holder.sol";
import "./ERC721Enumerable.sol";
import "./HexStrings.sol";
import "./Base64.sol";
import "./ItemsOfMetaverse.sol";


contract KingsOfMetaverse is ERC721Enumerable, ERC721URIStorage, ERC1155Holder {
    
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    using Strings for uint256;
    using HexStrings for uint160;
    mapping (address => uint[]) public lockedItems;
    ItemsOfMetaverse private itemsOfMetaverse;

    event MinterChanged(address indexed from, address to);

    constructor(ItemsOfMetaverse _itemsOfMetaverse) ERC721("Kings of metaverse", "KOM") {
        itemsOfMetaverse = _itemsOfMetaverse;
        // awardItem(msg.sender);

    }

    
    function tokenURI(uint256 id) public view override(ERC721, ERC721URIStorage) returns (string memory) {
      require(_exists(id), "not exist");
      return itemsOfMetaverse.uriBatch(lockedItems[ownerOf(id)]);
  }

    function awardItem(address player, uint256[] memory ids, uint256[] memory ammounts) public payable returns (uint256) {
        require(lockedItems[msg.sender].length == 0, "Already created King");
        require(ids.length == 7);
        for (uint i = 0; i < ids.length; i++) {
            require(itemsOfMetaverse.getItemType(i) == i);
        }        
        itemsOfMetaverse.safeBatchTransferFrom(msg.sender, address(this), ids, ammounts, "0x0");
        lockedItems[msg.sender] = ids;
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();

        _mint(player, newItemId);
        return newItemId;
    }

    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable, ERC1155Receiver) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
      if (_i == 0) {
          return "0";
      }
      uint j = _i;
      uint len;
      while (j != 0) {
          len++;
          j /= 10;
      }
      bytes memory bstr = new bytes(len);
      uint k = len;
      while (_i != 0) {
          k = k-1;
          uint8 temp = (48 + uint8(_i - _i / 10 * 10));
          bytes1 b1 = bytes1(temp);
          bstr[k] = b1;
          _i /= 10;
      }
      return string(bstr);
  }
}