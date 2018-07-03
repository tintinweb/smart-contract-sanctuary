pragma solidity ^0.4.24;

contract Bidding
{
	address public bidder;
	uint public current_bid_val;
	uint public last_bid_val = 0;
	address public last_bidder;
	address public admin;
	bool public active_bid;
	mapping(address=>uint) public balance;
	
	constructor() 
	{
		admin = tx.origin;
	}
	
	function placeBid(uint amount) public payable
	{
		last_bidder = bidder ;
		current_bid_val = amount;
		if(current_bid_val>last_bid_val)
		{
		bidder = msg.sender;
		balance[admin] += amount;  
		balance[msg.sender] -= amount;
		return;
		}
		else
		{
			bidder = last_bidder;
			return;
		}  
	}	
	
	function takeBackMoney() public 
	{
		if(msg.sender==last_bidder)
		{
			balance[msg.sender] += last_bid_val;
			balance[admin] -= last_bid_val;
			return;
		}
		else 
			return;
	}
	
	function showAdmin() returns(address)
	{
	    return admin;
	}
	function showBidder() returns(address)
	{
	    return bidder;
	}
	function showLastBidder() returns(address)
	{
	    return last_bidder;
	}
	function showCurrentBidValue() returns(uint)
	{
	    return current_bid_val;
	}
	function showLastBidValue() returns(uint)
	{
	    return last_bid_val;
	}
// 	function stopBid() 
// 	{
		
// 	}
}