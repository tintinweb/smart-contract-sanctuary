/**
 *Submitted for verification at Etherscan.io on 2021-09-12
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

contract GraJek {
    
    address payable public passenger;
    uint public auctionEndTime;
    uint public startPostal;
    uint public endPostal;
    
    uint public recommendedFare;
    
    address public driver;
    uint256 public lowestFareAmount;

    
    bool public ended = false;
    
    // Allowed withdrawals of previous bids
    mapping(address => uint) pendingReturns; // works like dictionary
    
    // Events that will be emitted on changes.
    event fareBidAmountDecreased(address bidder, uint amount);
    event AuctionEnded(address winner, uint amount);
    event locations(uint Postal);
    
    
    /// The auction has already ended.
    error AuctionAlreadyEnded();
    /// There is a bid that is lower or matches your bid
    error BidNotLowEnough(uint lowestFareAmount);
    /// The auction has not ended yet.
    error AuctionNotYetEnded();
    /// The function auctionEnd has already been called.
    error AuctionEndAlreadyCalled();
    /// You can place a bid on your own contract
    error PassengerCannotBid();
    /// You are not authorized to end the Auction
    error YouCannotEndAuction();
    /// Your payment != lowestFareAmount
    error YourPaymentDoesNotMatchLowestBid();
    /// You cannot withdrawal
    error YouCannotWithdraw();

    
    constructor (uint _durationMin, uint distanceKm, uint _startPostal, uint _endPostal) payable { 
        passenger = payable(msg.sender); // this sets the passenger wallet address as a public variable that can be accessed
        // require(passenger==address(0), "Invalid address");
        startPostal = _startPostal; 
        endPostal = _endPostal; 
        auctionEndTime = block.timestamp + _durationMin * 60; // time the passenger is willing to wait (min) 
        recommendedFare = distanceKm * 2;
        lowestFareAmount = msg.value;
        pendingReturns[passenger] += msg.value;
    }
    
    function placeBid() public payable { 
        
        
        // Revert the call if the bidding
        // period is over.
        if (block.timestamp > auctionEndTime)
            revert AuctionAlreadyEnded();
     
        // If the bid is not lower, send the
        // money back (the revert statement
        // will revert all changes in this
        // function execution including
        // it having received the money).
        if (msg.value >= lowestFareAmount)
            revert BidNotLowEnough(lowestFareAmount);
        
        // store the amount into a dictionary so that people can withdraw the amount themselves
        if(lowestFareAmount != 0)
            pendingReturns[driver] += lowestFareAmount;
        
        driver = msg.sender;
        lowestFareAmount = msg.value;
        emit fareBidAmountDecreased(msg.sender, msg.value);
        
    }
    
    function withdrawal() public returns (bool) {
        uint amount = pendingReturns[msg.sender]; // check the amount they need to receive
        
        if  (!ended && (passenger == msg.sender || driver == msg.sender)) 
            revert YouCannotWithdraw();
        
        if (amount > 0) {
            pendingReturns[msg.sender] = 0;
            
            if (!payable(msg.sender).send(amount)){
                pendingReturns[msg.sender] = amount;
                return false;
            }
            
        }
        return true;
    }
    
   
    
    function auctionEnd() public {
        if (passenger == msg.sender) {
            pendingReturns[passenger] -= lowestFareAmount;
            pendingReturns[driver] += (2*lowestFareAmount);
            ended = true;
            emit AuctionEnded(driver, lowestFareAmount);
        }
        else 
            revert YouCannotEndAuction();
    }
      
    
}