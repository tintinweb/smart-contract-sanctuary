// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract OpenAction {

    address public owner;
    address payable public beneficiary;
    uint public auctionEndTime;
    address public highestBidder;
    uint public highestBid;

    mapping(address => uint) pendingReturns;
    bool public ended;

    event HighestBidIncreased(address bidder, uint amount);
    event AuctionEnded(address winner, uint amount);

    /// The auction has already ended
    error AuctionAlreadyEnded();
    /// There is already higher or equal bid
    error BidNotHighEnough();
    /// The auction has not ended yet
    error AuctionNotYetEnded();
    /// The function auctionEnd has already been called
    error AuctionEndAlreadyCalled();
    /// Can't withdraw the highest bid
    error CantWithdrawHighestBid();

    constructor(address payable _beneficiary, uint _auctionEndTime) {
        owner = msg.sender;
        beneficiary = _beneficiary;
        auctionEndTime = block.timestamp + _auctionEndTime;
    }

    function bid() external payable {
        if (block.timestamp > auctionEndTime) {
            revert AuctionAlreadyEnded();
        }
        if (msg.value <= highestBid) {
           revert BidNotHighEnough();
        }

        if (highestBid != 0) {
            pendingReturns[highestBidder] = highestBid;
        }

        highestBidder = msg.sender;
        highestBid = msg.value;

        emit HighestBidIncreased(msg.sender, msg.value);
    }

    function auctionEnd() external {
        // 1. Conditions
        if (block.timestamp < auctionEndTime) {
            revert AuctionNotYetEnded();
        }
        if (ended) {
            revert AuctionEndAlreadyCalled();
        }
        // 2. Effects
        ended = true;
        emit AuctionEnded(highestBidder, highestBid);
        // 3. Interaction with other contracts
        beneficiary.transfer(highestBid);
    }

    function withdraw() external returns (bool) {
        if (msg.sender == highestBidder) {
            revert CantWithdrawHighestBid();
        }

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

}