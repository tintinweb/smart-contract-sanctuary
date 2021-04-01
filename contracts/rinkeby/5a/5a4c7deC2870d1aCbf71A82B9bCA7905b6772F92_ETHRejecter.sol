/**
 *Submitted for verification at Etherscan.io on 2021-03-31
*/

//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.8;

interface IAuctionModified {
    function createBid(uint256 tokenId, uint256 amount) external payable;
}

contract ETHRejecter {
    // Allows the contract to place a bid.
    function relayBid(
        address auction,
        uint256 tokenId,
        uint256 amount
    ) external payable {
        IAuctionModified(auction).createBid{value: amount}(tokenId, amount);
    }

    receive() external payable {
        // This will revert the ETH payment,
        // even though it's payable.
        assert(1 == 2);
    }
}