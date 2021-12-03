// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";

contract Storage {

    function batchTransferERC721(address collection, address destination, uint256[] calldata tokenIds) public {
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

    function approved(ERC721 erc721, uint256 tokenId) view internal returns (bool) {
        return erc721.isApprovedForAll(msg.sender, address(this)) || erc721.getApproved(tokenId) == address(this);
    }
}