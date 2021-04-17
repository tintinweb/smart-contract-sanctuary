/**
 *Submitted for verification at Etherscan.io on 2021-04-17
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.9.0;
contract InvoluteDownwardAuction {

    address public creator;
    address payable public beneficiary;

    struct Auction {
  
        uint auctionEndTime;
        uint auctionChecksum;
        uint lowestBid;
        bool lowestBidSet;
        bool auctionEnded;
        address lowestBidder;
        mapping(address => uint) pendingReturns;

    }

    mapping (uint => Auction) auctions;

    event AuctionStarted(uint auctionId, uint auctionChecksum, uint endTime);
    event LowestBidDecreased(uint auctionId, address bidder, uint amount);
    event AuctionEnded(uint auctionId, address winner, uint amount);

    constructor(address _beneficiary) {
        beneficiary = payable(_beneficiary);
        creator = msg.sender;
    }

  
    function createAuction(uint _auctionId, uint _auctionChecksum, uint _biddingTime) public returns (bool) {
        
        require(msg.sender == creator, "Only contract creator can start a new auction");
        Auction storage a = auctions[_auctionId];
        a.auctionEndTime = block.timestamp + _biddingTime;
        a.auctionChecksum = _auctionChecksum;
        a.lowestBidSet = false;
        a.auctionEnded = false;

        emit AuctionStarted(_auctionId, a.auctionChecksum, a.auctionEndTime);

    }

    function bid(uint _auctionId) public payable {
        
        Auction storage a = auctions[_auctionId];

        require(a.auctionEndTime > 0, "Auction not known.");
        require(block.timestamp <= a.auctionEndTime, "Auction already ended.");
        require(msg.value < a.lowestBid || !a.lowestBidSet, "There already is a lower bid.");

        if (a.lowestBidSet && a.lowestBid != 0) {         
            a.pendingReturns[a.lowestBidder] += a.lowestBid;
        }
        a.lowestBidSet = true;
        a.lowestBidder = msg.sender;
        a.lowestBid = msg.value;
        emit LowestBidDecreased(_auctionId, msg.sender, msg.value);
    }

    /// Withdraw a bid that was overbid.
    function withdraw(uint _auctionId) public returns (bool) {

        Auction storage a = auctions[_auctionId];
        
        uint amount = a.pendingReturns[msg.sender];
        if (amount > 0) {

            a.pendingReturns[msg.sender] = 0;

            if (!payable(msg.sender).send(amount)) {
                // No need to call throw here, just reset the amount owing
                a.pendingReturns[msg.sender] = amount;
                return false;
            }
        }
        return true;
    }


    function auctionEnd(uint _auctionId) public {
    
        Auction storage a = auctions[_auctionId];

        require(a.auctionEndTime > 0, "Auction not known.");
        require(block.timestamp >=  a.auctionEndTime, "Auction not yet ended.");
        require(!a.auctionEnded, "auctionEnd has already been called.");

        // 2. Effects
        a.auctionEnded = true;
        emit AuctionEnded(_auctionId, a.lowestBidder, a.lowestBid);

        // 3. Interaction
        beneficiary.transfer(a.lowestBid);

    }

}