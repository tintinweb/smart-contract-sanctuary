/**
 *Submitted for verification at BscScan.com on 2021-12-23
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IERC721 {

    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

pragma solidity ^0.8.4;

contract ERC721BulkTransfer {

    function transferBulk(address tokenAddress, address to, uint256[] calldata tokenIds) external {

        for (uint256 i = 0; i < tokenIds.length; i++) {
            IERC721(tokenAddress).safeTransferFrom(msg.sender, to, tokenIds[i]);
        }
    }
}