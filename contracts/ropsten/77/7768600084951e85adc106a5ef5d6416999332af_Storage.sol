// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";

/**
 * Simple contract to enable batched transfers of ERC721 and ERC1155 collections between addresses.
 */
contract Storage {

    /**
     * Transfers all items in this collection owned by the caller to the destination address.
     */
    function batchTransferAllERC721(address collection, address destination) public {
        ERC721 erc721 = ERC721(collection);
        uint256[] memory tokenIds = new uint256[](erc721.balanceOf(msg.sender));
        uint256 count = 0;
        uint256 index = 0;

        while (index != tokenIds.length) {
          if (erc721.ownerOf(count) == msg.sender) {
              tokenIds[index++] = count;
          }
          count++;
        }
        batchTransferERC721(collection, destination, tokenIds);
    }

    /**
     * Transfers the specified items in this collection to the destination address.
    */
    function batchTransferERC721(address collection, address destination, uint256[] memory tokenIds) public {
        for (uint i = 0; i < tokenIds.length; i++) {
            transferERC721(collection, destination, tokenIds[i]);
        }
    }

    function transferERC721(address collection, address destination, uint256 tokenId) public {
        ERC721 erc721 = ERC721(collection);
        require(msg.sender == erc721.ownerOf(tokenId), "only the token owner can transfer a token");
        require(approved(erc721, tokenId), "you must approve the contract for all to send multiple tokens");

        erc721.safeTransferFrom(msg.sender, destination, tokenId);
    }

    /**
     * Transfers the specified item in this collection to the destination address.
    */
    function approved(ERC721 erc721, uint256 tokenId) view internal returns (bool) {
        return erc721.isApprovedForAll(msg.sender, address(this)) || erc721.getApproved(tokenId) == address(this);
    }
}