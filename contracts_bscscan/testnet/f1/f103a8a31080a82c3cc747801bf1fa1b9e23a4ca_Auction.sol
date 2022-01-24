/**
 *Submitted for verification at BscScan.com on 2022-01-24
*/

pragma solidity ^0.5.0;
contract Auction {
//Declare All State Variables here
address internal auction_owner;
uint256 public auction_end;
uint256 public highestBid;
address payable public highestBidder;
//Define a constructor for your contract
constructor ( uint _biddingTime, string memory _brand, string memory
_Rnumber) public {
auction_owner= msg .sender;
auction_end = now +_biddingTime * 1 minutes ;
Mycar.Brand =_brand;
Mycar.Rnumber =_Rnumber;
Mycar.owner = auction_owner;
}
//Function for get auction details
function getAuctionDetails () public view returns
( uint256 , uint256 , address , address ) {
return (auction_end,highestBid,highestBidder,auction_owner);
}
//Define a structure for Vehicle Details
struct car {
string Brand;
string Rnumber;
address owner;
}
car public Mycar;
//Mapping that accepts the bidder's address as the key, and with the value type being the corresponding bid
mapping ( address => uint ) public bids;
event BidEvent ( address indexed highestBidder, uint256 highestBid);
event WithdrawalEvent ( address withdrawer, uint256 amount);
//Checks whether the bid is can be done
modifier bid_conditions (){
require ( now <= auction_end, "auction timeout" );
require (bids[ msg .sender]+ msg .value > highestBid, "cant't bid, make a higher Bid" );
require ( msg .sender != auction_owner, "Auction owner cant bid" );
require ( msg .sender != highestBidder, "Current HighestBidder cant bid" );
_;
}
//makes the contract ownable
modifier only_owner (){
require ( msg .sender == auction_owner);
_;
}
//Define Bidding function
function bid () public payable bid_conditions returns ( bool ){
highestBidder= msg .sender;
bids[ msg .sender]=bids[ msg .sender]+ msg .value;
highestBid=bids[ msg .sender];
emit BidEvent (highestBidder,highestBid);
return true ;
}
// check auction status
function auction_status () public view returns ( bool state){
state = now < auction_end;
}
//Withdraw function for loosers
function getAmount () public returns ( bool ){
require ( now > auction_end, "can't withdraw, Auction is still open" );
require ( msg .sender != auction_owner, "owner cant withdraw" );
require ( msg .sender != highestBidder, "HighestBidder cant withdraw" );
uint amount = bids[ msg .sender];
bids[ msg .sender]= 0 ;
msg .sender. transfer (amount);
emit WithdrawalEvent ( msg .sender,amount);
return true ;
}
//Withdraw Bid amount to owner address
function withdraw () public only_owner returns ( bool ){
require ( now > auction_end, "can't withdraw, Auction is still open" );
msg .sender. transfer (highestBid);
Mycar.owner = highestBidder;
emit WithdrawalEvent ( msg .sender,highestBid);
return true ;
}
}