// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract Mint_Auction {
/*parameter of the auction. Times are either
absolut unix timestamps or time periods in seconds*/
address payable public beneficiary;
uint public auctionEndTime;

//Current state of the auction
address public highestBidder;
uint public highestBid;

// Allowed withdrawls of the prev bid.
mapping(address => uint) pendingReturns;

//Set to reu at the end, dissallows any change.
// by default init to false
bool ended;

// events that will be ommited on changes
event HighestBidIncreased(address bidder, uint amount);
event AuctionEnded(address winner, uint amount);

/* errors that describe the failure. */
// triple lashed comments are called natspec comments.
// They will be shown as a user is asked to confirm a tx or
// when an error is displayed.

/// The auction already ended.
error AuctionAlreadyEnded();
/// There is already a higher or equal bid.
error BidNotHighEnough(uint highestBid);
/// The auction has not ended yet.
error AuctionNotYetEnded();
/// The function AuctionEnd has already been called
error AuctionEndAlreadyCalled();

/// Create a simple auction with `biddingTime`
/// seconds bidding time on behalf of the
/// beneficiary address `beneficiaryAddreaa`
constructor(
    uint biddingTime,
    address payable beneficiaryAddress
) {
    beneficiary = beneficiaryAddress;
    auctionEndTime = block.timestamp + biddingTime;
}

/// Bid on the auction with the value sen
/// together with the tx.
/// The value will only be refunded if
/// the auction is not won
function bid() external payable {
    //revert the call if the bidding period is over
    if(block.timestamp > auctionEndTime)
        revert AuctionAlreadyEnded();

    // if the bid is not higher, send the
    // the money back ( revert statement
    // will revert all changes in this
    // function execution including
    // it having recieved the money ).
    if(msg.value <= highestBid)
        revert BidNotHighEnough(highestBid);

    if(highestBid != 0) {
        // sending back the money by simply using
        // highestBidder.send(highestBid) is a security risk
        // because it could execute an intrusted contract.
        // it is always safer to let the recipients
        // withdraw thier money themself.
        pendingReturns[highestBidder] += highestBid;
    }  

    highestBidder = msg.sender;
    highestBid = msg.value;
    emit HighestBidIncreased(msg.sender, msg.value);

}

/// Withdraw a bid that was overbid.
function withdraw() external returns (bool) {
    uint amount = pendingReturns[msg.sender];
    if(amount > 0){
        // it is important to set this function to zero because the recepient
        // can call this function again as part o the recieving call
        // before `send` return.
        pendingReturns[msg.sender] = 0;

        if(!payable(msg.sender).send(amount)){
            // no need to call the throw here, just reset the amount owing
            pendingReturns[msg.sender] = amount;
            return false;
        }
    }
    return true;
}

/// End the auction and send the highest bid
/// to the beneficiary
function auctionEnd() external {
    // 1. conditions
    if(block.timestamp < auctionEndTime)
        revert AuctionNotYetEnded();
    if(ended)
        revert AuctionEndAlreadyCalled();

    // 2. Effects
    ended = true;
    emit AuctionEnded(highestBidder, highestBid);

    // 3. Interaction
    beneficiary.transfer(highestBid);
}
}