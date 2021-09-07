/**
 *Submitted for verification at Etherscan.io on 2021-09-07
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

contract GraJek {
    
    address payable public passenger;
    uint public auctionEndTime;
    uint public startPostal;
    uint public endPostal;
    
    
    
    address public driver;
    uint256 public fareAmount;
    uint256 public lowestFareAmount;
    
    bool ended = false;
    
    // Allowed withdrawals of previous bids
    mapping(address => uint) pendingReturns; // works like dictionary
    
    // Events that will be emitted on changes.
    event fareBidAmountDecreased(address bidder, uint amount);
    event AuctionEnded(address winner, uint amount);
    
    
    /// The auction has already ended.
    error AuctionAlreadyEnded();
    /// There is a bid that is lower or matches your bid
    error BidNotLowEnough(uint fareAmount);
    /// The auction has not ended yet.
    error AuctionNotYetEnded();
    /// The function auctionEnd has already been called.
    error AuctionEndAlreadyCalled();

    
    constructor (address payable _passengerWalletAddr, uint _durationMin, uint distanceKm, uint _startPostal, uint _endPostal) {
        
        passenger = _passengerWalletAddr;
        startPostal = _startPostal;
        endPostal = _endPostal;
        auctionEndTime = block.timestamp + _durationMin * 60; // time the passenger is willing to wait (min)
        fareAmount = 5;// passenger can set a reasonable starting bid or we can set a fixed starting point
        if (fareAmount < distanceKm * 2) {
            lowestFareAmount = fareAmount;
        } // passenger can set a reasonable starting bid or we can set a fixed starting point
        
        
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
        if (msg.value >= fareAmount)
            revert BidNotLowEnough(fareAmount);
        
        // store the amount into a dictionary so that people can withdraw the amount themselves
        if(lowestFareAmount != 0)
            pendingReturns[driver] += lowestFareAmount;
        
        driver = msg.sender;
        lowestFareAmount = msg.value;
        emit fareBidAmountDecreased(msg.sender, msg.value);
        
    }
    
    function withdrawal() public returns (bool) {
        uint amount = pendingReturns[msg.sender]; // check the amount they need to receive
        
        if (amount > 0) {
            pendingReturns[msg.sender] = 0;
            
            if (!payable(msg.sender).send(amount)){
                pendingReturns[msg.sender] = amount;
                return false;
            }
        }
        return true;
    }
    
    function cancelAuction() public {
        
        if (passenger == msg.sender) {
            pendingReturns[driver] += lowestFareAmount;
            ended = true;
        }
        else {
            if (block.timestamp < auctionEndTime)
                revert AuctionNotYetEnded();
        }
        
    }
    
     
    function auctionEnd() public {
     
     if (block.timestamp < auctionEndTime)
            revert AuctionNotYetEnded();
        if (ended)
            revert AuctionEndAlreadyCalled();
            
        ended = true;
        emit AuctionEnded(driver, lowestFareAmount);

        passenger.transfer(2 * lowestFareAmount);   
    }
    
    
}