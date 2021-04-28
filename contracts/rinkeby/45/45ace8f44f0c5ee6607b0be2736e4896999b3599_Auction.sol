/**
 *Submitted for verification at Etherscan.io on 2021-04-27
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;


contract Auction {
    address payable public seller;
    uint public latestBid;
    address payable public latestBidder;

    bool finished;

    constructor(uint startingPrice) public {
        //set `seller` field to contract creator,
        seller = payable(msg.sender);
        //set `latestBid` field to `startingPrice` number of ethers.
        latestBid = startingPrice;
    }

    function bid() public payable {
        require(msg.value > latestBid, "The bid price is not greater than the latest bid.");
        require(!finished, "The bid is already finished.");

        uint previousBid = latestBid;
        address payable previousBidder = latestBidder;

        latestBid = msg.value;
        latestBidder = payable(msg.sender);

        // //return previous bid to the bidder.
        if (previousBidder != address(0)) {
            previousBidder.transfer(previousBid);
        }
    }

    function finishAuction() public payable {
        require(msg.sender == seller, "Caller is not owner.");
        require(!finished, "The bid is already finished.");

        finished = true;
        seller.transfer(latestBid);
    }
}