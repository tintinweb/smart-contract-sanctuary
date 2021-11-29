//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IERC721 {
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;
}

contract Dispatch {
    function dispatchToken(
        IERC721 token,
        address[] memory recipients,
        uint256[] memory tokenIds
    ) external payable {
        for (uint256 i = 0; i < recipients.length; i++) {
            token.transferFrom(msg.sender, recipients[i], tokenIds[i]);
        }
    }
}