/**
 *Submitted for verification at BscScan.com on 2021-12-24
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC721 {
 function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

contract MultitransferERC721 {
    function multitransfer(
        address erc721Address,
        address recipient,
        uint256[] calldata tokenIds
    ) external {
        IERC721 erc721 = IERC721(erc721Address);

        uint256 tokenIdsCount = tokenIds.length;

        for (uint256 i = 0; i < tokenIdsCount; i++) {
            erc721.safeTransferFrom(msg.sender, recipient, tokenIds[i]);
        }
    }
}