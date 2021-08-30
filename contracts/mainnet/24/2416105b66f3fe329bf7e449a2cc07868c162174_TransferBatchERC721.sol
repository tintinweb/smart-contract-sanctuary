/**
 *Submitted for verification at Etherscan.io on 2021-08-30
*/

// SPDX-License-Identifier: MIT
pragma solidity =0.8.3;

interface IERC721 {
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

contract TransferBatchERC721 {
    address immutable owner;

    constructor() {
        owner = msg.sender;
    }
    
    function batchSafeTransferFrom(IERC721 nft, address[] calldata recipients, uint256[] calldata tokenIds) external {
        require(recipients.length == tokenIds.length);
        require(owner == msg.sender);
        
        for (uint256 i = 0; i < recipients.length; i++) {
            nft.safeTransferFrom(msg.sender, recipients[i], tokenIds[i]);
        }
    }
}