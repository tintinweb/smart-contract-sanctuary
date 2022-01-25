/**
 *Submitted for verification at BscScan.com on 2022-01-25
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract SimpleAuction {
    address payable public beneficiary; // 最终获胜者
    uint256 public auctionEnd; //拍卖结束时间

    address public highestBidder; // 最高价的地址
    uint256 public highestBid; // 最高价

    mapping(address => uint256) pendingReturns;

    bool ended;

    event HighestBidIncreased(address bidder, uint256 amount);
    event AuctionEnded(address winner, uint256 amount);

    constructor(uint256 _biddingTime, address payable _beneficiary) {
        beneficiary = _beneficiary;
        auctionEnd = block.timestamp + _biddingTime;
    }

    function bid() public payable {
        require(block.timestamp <= auctionEnd, "Auction already ended.");
        require(msg.value > highestBid, "There already is a higher bid.");
        if (highestBid != 0) {
            pendingReturns[highestBidder] += highestBid;
        }
        highestBidder = msg.sender;
        highestBid = msg.value;
        emit HighestBidIncreased(msg.sender, msg.value);
    }

    function withdraw() public returns (bool) {
        uint256 amount = pendingReturns[msg.sender];
        if (amount > 0) {
            pendingReturns[msg.sender] = 0;

            bool result = payable(msg.sender).send(amount);
            if (!result) {
                pendingReturns[msg.sender] = amount;
                return false;
            }
        }
        return true;
    }

    function callAuctionEnd() public {
        // 1.条件
        require(block.timestamp > auctionEnd, "Auction not yet ended.");
        require(!ended, "auctionEnd has already been called.");

        //2. 生效
        ended = true;
        emit AuctionEnded(highestBidder, highestBid);

        // 3.交互
        beneficiary.transfer(highestBid);
    }
}