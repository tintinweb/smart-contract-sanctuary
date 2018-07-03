pragma solidity ^0.4.21;

 contract Auction
 {
 	address public bidder;
 	uint public bid_value ;
 	bool public isAuction;
 	uint public last_bid;
 	address public last_bidder;
 	address private admin_address;

    constructor() public
 	{
 		admin_address=msg.sender;
 		isAuction=true;
 	}

 	function bid(uint amount) public payable
 	{
 		if(amount<bid_value||isAuction==false)
 			return;
 		last_bid=bid_value;
 		last_bidder=bidder;
 		bidder=msg.sender;
 		bid_value=amount;

 	}

 	function take_back_money() public
 	{
 		if(msg.sender==last_bidder)
 			last_bidder.transfer(last_bid);

 	}

 	function stop_auction() public
 	{
 		if(msg.sender==admin_address)
 			isAuction=false;
 	}
 }