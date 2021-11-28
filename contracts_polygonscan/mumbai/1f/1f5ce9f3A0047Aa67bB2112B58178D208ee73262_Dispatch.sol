//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IERC721 {
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) external returns (bool);
}

contract Dispatch {
    uint256 private constant fee = 0.01 ether;
    address private constant vault = 0xa048fC2D9f7a18ba1B29b0619D4BBb3012B2c0E1;

    function dispatchToken(
        IERC721 token,
        address[] memory recipients,
        uint256[] memory tokenIds
    ) external payable {
        payable(vault).transfer(fee);
        for (uint256 i = 0; i < recipients.length; i++) {
            token.safeTransferFrom(
                msg.sender,
                recipients[i],
                tokenIds[i],
                "0x1"
            );
        }
    }
}