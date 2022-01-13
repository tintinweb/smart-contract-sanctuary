/**
 *Submitted for verification at Etherscan.io on 2022-01-13
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.7.0;
contract AwesomePictureAuctions {

    struct AuctionInstance{
        string   _description;
        address  payable _beneficiary;
        uint256  _startTime;
        uint256  _endTime;
        uint256  _startingPrice;
        uint256  _maxBid;
        address  _maxBidder;
        mapping(address => uint256) _bidderDeposits;
        bool _exists;
    }

    uint256 _auctionIndex;
    mapping(uint => AuctionInstance) auctions;

    event AuctionCreated(uint  id, address beneficiary, string description, uint256 startingPrice);
    event MaxBidRegistered(address maxBidder, uint256 maxBid);
    event DepositWithdrawn(address bidder, uint256 bidAmount);
    event AuctionClosed(uint256 maxBid, address maxBidder, address beneficiary, uint256 time);

    constructor() {
        _auctionIndex  = 0;
    }

    function addAuction(string memory description, uint256 startingPrice, uint256 startTime, uint256 endTime) public returns (uint256){
        _auctionIndex++;
        AuctionInstance storage auction = auctions[_auctionIndex];
        auction._description = description;
        auction._beneficiary =     msg.sender;
        auction._startTime =     startTime;
        auction._endTime= endTime;
        auction._startingPrice  = startingPrice;
        auction._exists = true;
        emit AuctionCreated(_auctionIndex, msg.sender, description, startingPrice);
        return _auctionIndex;
    }

    function bid(uint auctionIndex) public payable {
        AuctionInstance storage auction = auctions[auctionIndex];
        require(auction._exists, "Auction not registered");
        require (msg.value > auction._maxBid &&  msg.value >= auction._startingPrice, "Bid amount is to small");
        require(block.timestamp <= auction._endTime, "Auction has ended");

        auction._bidderDeposits[msg.sender] += msg.value;
        auction._maxBid = msg.value;
        auction._maxBidder = msg.sender;
        emit MaxBidRegistered(auction._maxBidder, auction._maxBid);
    }

    function retrieveDescription(uint auctionIndex) public view returns (string memory){
        return auctions[auctionIndex]._description;
    }

    function retrieveStartingPrice(uint auctionIndex) public view returns (uint256){
        return auctions[auctionIndex]._startingPrice;
    }

    function retrieveStartTime(uint auctionIndex) public view returns (uint256){
        return auctions[auctionIndex]._startTime;
    }

    function retrieveEndTime(uint auctionIndex) public view returns (uint256){
        return auctions[auctionIndex]._endTime;
    }

    function retrieveMaxBid(uint auctionIndex) public view returns (uint256){
        return auctions[auctionIndex]._maxBid;
    }

    function retrieveMaxBidder(uint auctionIndex) public view returns (address){
        return auctions[auctionIndex]._maxBidder;
    }

    function withdraw(uint auctionIndex) public{
        AuctionInstance storage auction = auctions[auctionIndex];
        require(auction._exists, "Auction not registered");
        require(block.timestamp >= auction._endTime, "Auction has not yet ended!");
        uint256 bidAmount = auction._bidderDeposits[msg.sender];
        if(msg.sender == auction._maxBidder){
            bidAmount = bidAmount - auction._maxBid;
        }
        require(bidAmount>0, "No deposit found for bidder");

        auction._bidderDeposits[msg.sender] = 0;

        if (payable(msg.sender).send(bidAmount)) {
            emit DepositWithdrawn(msg.sender, bidAmount);
        }else{
            auction._bidderDeposits[msg.sender] += bidAmount;
        }
    }

    function closeAuction(uint auctionIndex) public{
        AuctionInstance storage auction = auctions[auctionIndex];
        require(auction._exists, "Auction not registered");
        require(block.timestamp >= auction._endTime , "Auction cannot be closed" );
        auction._beneficiary.transfer(auction._maxBid);
        emit AuctionClosed(auction._maxBid, auction._maxBidder, auction._beneficiary, block.timestamp);
        delete auctions[auctionIndex];
    }
}