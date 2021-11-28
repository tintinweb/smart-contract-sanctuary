//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IERC721 {
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external returns (bool);
}

contract Dispatch {
    function dispatchToken(
        IERC721 token,
        address[] memory recipients,
        uint256[] memory values
    ) external {
        uint256 total = 0;

        for (uint256 i = 0; i < recipients.length; i++) total += values[i];

        require(token.transferFrom(msg.sender, address(this), total));

        for (uint256 i = 0; i < recipients.length; i++)
            require(token.transferFrom(msg.sender, recipients[i], values[i]));
    }
}