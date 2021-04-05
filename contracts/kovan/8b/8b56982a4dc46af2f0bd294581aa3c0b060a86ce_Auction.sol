/**
 *Submitted for verification at Etherscan.io on 2021-04-05
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

interface NFT {
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

contract Auction {
    NFT nft = NFT(0x3740Cc98aA4eeb70850112b7Ac2d0b1c9fcbb49c);
    uint public auctionEndTime;

    address public highestBidder;
    uint public highestBid;

    address public gov;

    mapping(address => uint) public pendingReturns;
    mapping(address => uint) public fundsByBidder;

    bool ended;
    bool started;

    event HighestBidIncreased(address bidder, uint amount);
    event Ended(address winner, uint amount);

    constructor(
        address _governance
    ) {
        gov = _governance;
    }

    // Modifier for governance.
    modifier onlyGov() {
        require(msg.sender == gov, "!governance");
        _;
    }

    // start auction
    // This function can only be called by Governance.
    function startAuction(uint auctionDuration) public onlyGov {
        auctionEndTime = block.timestamp + auctionDuration;
        started = true;
    }

    // Bid
    // Everyone can call this function.
    function bid() public payable {
        require(started, "This auction has not been started.");
        require(
            block.timestamp <= auctionEndTime,
            "This Auction has already been ended."
        );

        uint newBid = fundsByBidder[msg.sender] + msg.value;

        require(
            newBid > highestBid,
            "There already is a higher bid than yours."
        );

        if (highestBid > 0) {
            pendingReturns[highestBidder] = highestBid;
            if (fundsByBidder[msg.sender] > 0) {
                pendingReturns[msg.sender] = 0;
            }
        }
        fundsByBidder[msg.sender] = newBid;
        highestBidder = msg.sender;
        highestBid = fundsByBidder[msg.sender];
        emit HighestBidIncreased(highestBidder, highestBid);
    }

    function withdraw() public returns (bool) {
        uint amount = pendingReturns[msg.sender];
        if (amount > 0) {
            pendingReturns[msg.sender] = 0;

            if (!payable(msg.sender).send(amount)) {
                pendingReturns[msg.sender] = amount;
                return false;
            }
        }
        return true;
    }

    // End the auction.
    // This function can only be called by governance.
    function endAuction(uint nftID) public onlyGov {
        require(started, "This auction has not been started.");
        require(!ended, "This auction has already been ended.");

        ended = true;
        nft.safeTransferFrom(gov, highestBidder, nftID);
        uint balance = address(this).balance;
        payable(gov).transfer(balance);
        emit Ended(highestBidder, highestBid);
    }

    // This function shows current highestBid.
    function currentHighestBid() public view returns (uint) {
        require(started, "This auction has not been started.");
        require(!ended, "This auction has already been ended.");
        return highestBid;
    }

    // Check if the auction has been stared or not.
    function startedStatus() public view returns (bool) {
        return started;
    }

    // Check if the auction has been eneded or not.
    function endedStatus() public view returns (bool) {
        return ended;
    }

    // Return the winner bid.
    function winnerBid() public view returns (uint) {
        require (ended, "The auction has not been ended.");
        return highestBid;
    }
}