/**
 *Submitted for verification at polygonscan.com on 2022-01-23
*/

pragma solidity 0.8.0;

contract SimpleAuction{
	
	address payable public beneficiary;
	uint public auctionEndTime;

	address public highestBidder;
	uint public highestBid;

	mapping(address => uint) public pendingReturns;

	bool ended = false;
	
	event HighestBidIncrease(address bidder, uint amount);
	event AuctionEnded(address winner, uint amount);

	constructor(uint _biddingTime, address payable _beneficiary){
		beneficiary = _beneficiary;
		auctionEndTime = block.timestamp + _biddingTime;
	}

	function bid() public payable{
		if(block.timestamp > auctionEndTime){
			revert("The auction has ended");
		}
		
		if(msg.value <= highestBid){
			revert("The bid is not up to the high value bidded");
		}

		if(highestBid != 0){
			pendingReturns[highestBidder] += highestBid;
		}

		highestBidder = msg.sender;
		highestBid = msg.value;
		emit HighestBidIncrease(msg.sender, msg.value);
	}

	function withdraw() public returns(bool){
		uint amount = pendingReturns[msg.sender];
		if (amount > 0) {
			pendingReturns[msg.sender] = 0;

			if(!payable(msg.sender).send(amount)){
				pendingReturns[msg.sender] = amount;
				return false;
			}
		}
		return true;
	}

	function auctionEnd() public{
		if(block.timestamp < auctionEndTime){
			revert("The auction is not ended yet");
		}
		if (ended){
			revert("The function auctionended has already called");
		}
		ended = true;
		emit AuctionEnded(highestBidder, highestBid);

		beneficiary.transfer(highestBid);
	}
}