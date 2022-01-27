// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";
import "./IERC1155.sol";
import "./IERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * Simple contract to enable batched transfers of ERC721 and ERC1155 collections between addresses.
 */
contract BatchTransfer {

    event BatchTransferred(uint256 indexed tokensTransferred, uint256 indexed lastTokenTransferred);

    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;

    /**
     * Transfers all of the given tokens in this collection between addresses.
     */ 
    function batchTransferAllERC1155(address collection, uint256 tokenId, address destination) external {
        IERC1155 erc1155 = IERC1155(collection);
        erc1155.safeTransferFrom(msg.sender, destination, tokenId, erc1155.balanceOf(msg.sender, tokenId), "");
    }

    /**
     * Transfers the specified amount of the given tokens in this collection between addresses.
     */ 
    function batchTransferERC1155(address collection, uint256 tokenId, uint256 tokenValue, address destination) external {
        IERC1155 erc1155 = IERC1155(collection);
        erc1155.safeTransferFrom(msg.sender, destination, tokenId, tokenValue, "");
    }

    /**
     * Transfers all items in this collection which are owned by the caller to the destination address.
     */
    function batchTransferAllERC721(address collection, address destination) external {
        batchTransferSomeERC721(collection, destination, 0, type(uint256).max);
    }

    /**
     * Transfers all items in this collection which are owned by the caller to the destination address.
     *
     * If the contract implements ERC721Enumerable this call will directly look up the tokens for the calling
     * address.  Otherwise it will search all tokens, optionally starting at `startID`.
     */
    function batchTransferSomeERC721(address collection, address destination, uint256 startId, uint256 max) public {
        IERC721 erc721 = IERC721(collection);
        uint256 avail = erc721.balanceOf(msg.sender);
        uint256 currentToken;
        uint256 numberToTransfer = avail;
        if (max < avail) numberToTransfer = max;

        if (erc721.supportsInterface(_INTERFACE_ID_ERC721_ENUMERABLE)) {
            IERC721Enumerable enumerable = IERC721Enumerable(collection);
            for (uint256 i = numberToTransfer; i > 0; i--) {
                currentToken = enumerable.tokenOfOwnerByIndex(msg.sender, 0);
                erc721.safeTransferFrom(msg.sender, destination, currentToken);
            }
        } else {
            uint256 counter = startId;
            uint256 remaining = numberToTransfer;
            while (remaining > 0) {
                if (erc721.ownerOf(counter) == msg.sender) {
                    currentToken = counter;
                    erc721.safeTransferFrom(msg.sender, destination, counter);
                    --remaining;
                }
                counter++;
            }
        }

        emit BatchTransferred(numberToTransfer, currentToken);
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