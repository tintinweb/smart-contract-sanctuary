// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Enumerable.sol";
import "./IERC165.sol";

/**
 * Simple contract to enable batched transfers of ERC721 and ERC1155 collections between addresses.
 */
contract Storage {

    /**
     * Transfers all items in this collection owned by the caller to the destination address.
     */
    function batchTransferAllERC721(address collection, address destination) public {
        IERC721 erc721 = IERC721(collection);

        uint256[] memory tokenIds = new uint256[](erc721.balanceOf(msg.sender));
        bytes4 signature = IERC721Enumerable.tokenOfOwnerByIndex.selector;

        IERC165 erc165 = IERC165(collection);
        if (erc165.supportsInterface(signature)) {
            IERC721Enumerable enumerable = IERC721Enumerable(collection);
            
            for (uint i = 0; i < tokenIds.length; i++) {
                tokenIds[i] = enumerable.tokenOfOwnerByIndex(msg.sender, i);
            }
        
        } else {
            require(false, "did not detect enumerable interface");
            uint256 count = 0;
            uint256 i = 0;

            while (i != tokenIds.length) {
                if (erc721.ownerOf(count) == msg.sender) {
                    tokenIds[i++] = count;
                }
                count++;
            }
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
        IERC721 erc721 = IERC721(collection);
        require(msg.sender == erc721.ownerOf(tokenId), "only the token owner can transfer a token");
        require(approved(erc721, tokenId), "you must approve the contract for all to send multiple tokens");

        erc721.safeTransferFrom(msg.sender, destination, tokenId);
    }

    /**
     * Transfers the specified item in this collection to the destination address.
    */
    function approved(IERC721 erc721, uint256 tokenId) view internal returns (bool) {
        return erc721.isApprovedForAll(msg.sender, address(this)) || erc721.getApproved(tokenId) == address(this);
    }
}