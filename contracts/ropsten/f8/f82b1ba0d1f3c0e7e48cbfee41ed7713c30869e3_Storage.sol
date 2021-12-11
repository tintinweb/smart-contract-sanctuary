// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";
import "./IERC1155.sol";
import "./IERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * Simple contract to enable batched transfers of ERC721 and ERC1155 collections between addresses.
 */
contract Storage {

    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;

    /**
     * Transfers all of the given tokens in this collection between addresses.
     */ 
    function batchTransferAllERC1155(address collection, uint256 tokenId, address destination) external {
        IERC1155 erc1155 = IERC1155(collection);
        erc1155.safeTransferFrom(msg.sender, destination, tokenId, erc1155.balanceOf(msg.sender, tokenId), "0x0");
    }

    /**
     * Transfers the specified amount of the given tokens in this collection between addresses.
     */ 
    function batchTransferERC1155(address collection, uint256 tokenId, uint256 tokenValue, address destination) external {
        IERC1155 erc1155 = IERC1155(collection);
        erc1155.safeTransferFrom(msg.sender, destination, tokenId, tokenValue, "0x0");
    }

    /**
     * Transfers all items in this collection which are owned by the caller to the destination address.
     */
    function batchTransferAllERC721(address collection, address destination) external {
        IERC721 erc721 = IERC721(collection);
        IERC165 erc165 = IERC165(collection);

        if (erc165.supportsInterface(_INTERFACE_ID_ERC721_ENUMERABLE)) {
            IERC721Enumerable enumerable = IERC721Enumerable(collection);
            
            for (uint i = 0; i < erc721.balanceOf(msg.sender); i++) {
                erc721.safeTransferFrom(msg.sender, destination, enumerable.tokenOfOwnerByIndex(msg.sender, i));
            }
        
        } else {

            uint256 count = 0;
            uint256 i = 0;

            while (i != erc721.balanceOf(msg.sender)) {
                if (erc721.ownerOf(count) == msg.sender) {
                    erc721.safeTransferFrom(msg.sender, destination, count);
                }
                count++;
            }
        }
    }   

    /**
     * Transfers the specified items in this collection to the destination address.
    */
    function batchTransferERC721(address collection, address destination, uint256[] calldata tokenIds) external {
        for (uint i = 0; i < tokenIds.length; i++) {
            IERC721 erc721 = IERC721(collection);
            erc721.safeTransferFrom(msg.sender, destination, tokenIds[i]);
        }
    }

    /**
     * Transfers the specified item in this collection to the destination address.
    */
    function transferERC721(address collection, address destination, uint256 tokenId) external {
        IERC721 erc721 = IERC721(collection);
        erc721.safeTransferFrom(msg.sender, destination, tokenId);
    }
}