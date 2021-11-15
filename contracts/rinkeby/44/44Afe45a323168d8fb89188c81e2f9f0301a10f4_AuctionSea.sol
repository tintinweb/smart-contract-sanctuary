//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract AuctionSea {
    struct Auction {
        uint256 highestBid;
        uint256 closingTime;
        address payable highestBidder;
        address payable originalOwner;
        bool isActive;
    }

    // NFT id => Auction data
    mapping (uint256 => Auction) public auctions;

    /**
     * New Auction Opened Event
     * @param nftId Auction NFT Id
     * @param startingBid NFT starting bid price
     * @param closingTime Auction close time
     * @param originalOwner Auction creator address
     */
    event NewAuctionOpened (uint256 nftId, uint256 startingBid, uint256 closingTime, address originalOwner);

    /**
     * Auction Closed Event
     * @param nftId Auction NFT id
     * @param highestBid Auction highest bid
     * @param highestBidder Auction highest bidder
     */
    event AuctionClosed (uint256 nftId, uint256 highestBid, address highestBidder);

    /**
     * Bid Placed Event
     * @param nftId Auction NFT id
     * @param bidPrice Bid price
     * @param bidder Bidder address
     */
    event BidPlaced (uint256 nftId, uint256 bidPrice, address bidder);

    /**
     * Open Auction
     * @param _nftId NFT id
     * @param _sBid Starting bid price
     * @param _duration Auction opening duration time
     */
    function openAuction(uint256 _nftId, uint256 _sBid, uint256 _duration) external {
        require(auctions[_nftId].isActive == false, "Ongoing auction detected");
        require(_duration > 0 && _sBid > 0, "Invalid input");

        // Need to check nft owner

        // NFT Transfer to contract

        // Opening new auction
        auctions[_nftId].highestBid = _sBid;
        auctions[_nftId].closingTime = block.timestamp + _duration;
        auctions[_nftId].highestBidder = payable(msg.sender);
        auctions[_nftId].originalOwner = payable(msg.sender);
        auctions[_nftId].isActive = true;

        emit NewAuctionOpened(_nftId, auctions[_nftId].highestBid, auctions[_nftId].closingTime, auctions[_nftId].highestBidder);
    }

    /**
     * Place Bid
     * @param _nftId NFT id
     */
    function placeBid(uint256 _nftId) external payable {
        require(auctions[_nftId].isActive == true, "Not active auction");
        require(auctions[_nftId].closingTime > block.timestamp, "Auction is closed");
        require(msg.value > auctions[_nftId].highestBid, "Bid is too low");

        // Transfer ETH to Previous Highest Bidder
        auctions[_nftId].highestBidder.transfer(auctions[_nftId].highestBid);

        auctions[_nftId].highestBid = msg.value;
        auctions[_nftId].highestBidder = payable(msg.sender);

        emit BidPlaced(_nftId, auctions[_nftId].highestBid, auctions[_nftId].highestBidder);
    }

    /**
     * Close Auction
     * @param _nftId NFT id
     */
    function closeAuction(uint256 _nftId) external {
        require(auctions[_nftId].isActive == true, "Not active auction");
        require(auctions[_nftId].closingTime <= block.timestamp, "Auction is not closed");

        // Transfer ETH to NFT Owner
        if (auctions[_nftId].originalOwner != auctions[_nftId].highestBidder) {
            auctions[_nftId].originalOwner.transfer(auctions[_nftId].highestBid);
        }

        // Transfer NFT to Highest Bidder

        // Close Auction
        auctions[_nftId].isActive = false;

        emit AuctionClosed(_nftId, auctions[_nftId].highestBid, auctions[_nftId].highestBidder);
    }
}

