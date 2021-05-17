/**
 *Submitted for verification at Etherscan.io on 2021-05-16
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.1;

/*
VERSION DATE: 29/04/2021
*/

abstract contract TokenAddress 
{
	function ownerOf(uint256 tokenId) public view virtual returns (address);
	function getApproved(uint256 tokenId) public view virtual returns (address);
	function transferFrom(address from, address to, uint256 tokenId) public virtual;
}

contract Owned 
{
	address public owner;
	
    constructor()
	{
        owner = msg.sender;
    }

    function changeOwner(address newOwner) public onlyOwner
	{
		require(newOwner != address(0), "wrong address");
		require(newOwner != owner, "wrong address");

        owner = newOwner;
    }
	
	modifier onlyOwner {
        require(msg.sender == owner, "wrong owner");
        _;
    }
}

contract ReturnedAuction is Owned
{
	struct Auction
	{
        address seller;
		address tokenAddr;
		uint tokenId;
		uint minIncrement;
		uint32 startTime;
		uint32 endTime;
		uint highestBindingBid;
		address highestBidder;
    }

	uint public iterAuction = 0;
	mapping(uint256 => Auction) idAuction;						
	mapping(address => mapping(uint => uint)) addrAuction;  		// tokenAddr => tokenId => idAuction
	
	event CreateAuction(uint auctionId, address tokenAddr, uint tokenId);
	event Bid(uint auctionId, address bidder, uint bid);
	event ResolveAuction(uint auctionId, address withdrawalAccount, uint amount);
	
	uint256 public feeValue;
	uint8 public feePercent;
	uint32 deployTime;

	function timenow() public view returns(uint32) { return uint32(block.timestamp); }

	constructor(uint8 _feePercent)
	{
		require(_feePercent<=50, "wrong value");
		feePercent = _feePercent;
		deployTime = timenow();
	}
	
	function createAuction( 
		address tokenAddr, 
		uint256 tokenId, 
		
		uint beginPrice,
		uint minIncrement,
		
		uint32 startTime,
		uint32 endTime
	) public
	{
		TokenAddress ta = TokenAddress(tokenAddr);
		require( ta.ownerOf(tokenId) == msg.sender, "token is not owned" );
		require( ta.getApproved(tokenId) == address(this), "token is not approved" );
		
		require(addrAuction[tokenAddr][tokenId]==0, "auction already exists");
		
		// up to 1 month (=31*24*3600), the time can be set relative to the current one
		if ( startTime < 2678400 ) startTime += timenow();
		if ( endTime < 2678400 ) endTime += timenow();

		require( startTime > deployTime, "wrong time" );
		require( startTime < endTime, "wrong time" );
		require( endTime > timenow(), "wrong time" );

		require( beginPrice > 0, "beginPrice is zero" );
		require( minIncrement > 0, "minIncrement is zero" );
		
        Auction memory auction = Auction(
            msg.sender,
			tokenAddr,
			tokenId,
			minIncrement,
			startTime,
			endTime,
			beginPrice,
			address(0)
        );

		iterAuction++;
		idAuction[iterAuction] = auction;
		addrAuction[tokenAddr][tokenId] = iterAuction;

        emit CreateAuction(iterAuction, tokenAddr, tokenId);
    }

	function clearAuction( address tokenAddr, uint256 tokenId ) public
	{
		TokenAddress ta = TokenAddress(tokenAddr);
		require( ta.ownerOf(tokenId) == msg.sender, "token is not owned" );
		require( ta.getApproved(tokenId) == address(this), "token is not approved" );
		
		uint findAuction = addrAuction[tokenAddr][tokenId];
		
		require( findAuction!=0, "auction don`t exists");
		
		require( idAuction[findAuction].endTime < timenow(), "auction must be ended");
		require( idAuction[findAuction].highestBidder == address(0), "auction must be resolved");
		
		addrAuction[tokenAddr][tokenId] = 0;
	}

	function placeBid(uint256 auctionId) public payable
	{
		require(auctionId > 0 && auctionId <= iterAuction, "wrong auctionId");
		Auction storage auction = idAuction[auctionId];
		
		require( timenow() >= auction.startTime, "auction hasn't started yet" );
		require( timenow() <= auction.endTime, "auction already ended" );
		
		require(msg.sender != auction.seller, "bidder equal owner");
		require(msg.sender != auction.highestBidder, "bidder equal highestBidder");
		
		uint newBid = msg.value;
		require(newBid >= auction.highestBindingBid + auction.minIncrement, "not overbid" );

		if (auction.highestBidder != address(0)) payable(auction.highestBidder).transfer(auction.highestBindingBid);

		auction.highestBindingBid = newBid;
		auction.highestBidder = msg.sender;	

		emit Bid(auctionId, msg.sender, newBid);
	}

	function getAuction(uint256 auctionId) public view returns
    (
        address seller,
		address tokenAddr,
		uint tokenId,
        uint minIncrement,
        uint32 startTime,
		uint32 endTime,
		uint highestBindingBid,
		address highestBidder,
		string memory status
    ){
		require(auctionId > 0 && auctionId <= iterAuction, "wrong auctionId");
		Auction storage auction = idAuction[auctionId];
		
		seller = auction.seller;
		tokenAddr = auction.tokenAddr;
		tokenId = auction.tokenId;
        minIncrement = auction.minIncrement;
        startTime = auction.startTime;
		endTime = auction.endTime;
		highestBindingBid = auction.highestBindingBid;
		highestBidder = auction.highestBidder;
		
		if ( timenow() < auction.startTime ) status = "waiting";
		else
		if ( timenow() < auction.endTime ) status = "bidding";
		else 
		status = "ended";
    }

	function resolveAuction(uint256 auctionId) public
	{
		require(auctionId > 0 && auctionId <= iterAuction, "wrong auctionId");
		Auction storage auction = idAuction[auctionId];
		
		require( timenow() > auction.endTime, "auction hasn't ended yet" );
		require( msg.sender == auction.seller || msg.sender == auction.highestBidder, "only seller or winner" );

		uint withdrawalAmount = auction.highestBindingBid;
		require(withdrawalAmount != 0, "withdrawalAmount is zero");
		auction.highestBindingBid = 0;

		require(auction.highestBidder != address(0), "auction must be cleared");

		TokenAddress ta = TokenAddress(auction.tokenAddr);
		
		addrAuction[auction.tokenAddr][auction.tokenId] = 0;
		
		address withdrawalAccount;
		
		if( ta.ownerOf(auction.tokenId) == auction.seller && ta.getApproved(auction.tokenId) == address(this) )
		{
			withdrawalAccount = auction.seller;
			
			uint curFee = withdrawalAmount * feePercent / 100;
			feeValue = feeValue + curFee;
			withdrawalAmount = withdrawalAmount - curFee;
			
			ta.transferFrom(auction.seller, auction.highestBidder, auction.tokenId);
		}
		else
		{
			withdrawalAccount = auction.highestBidder;
		}
		
		payable(withdrawalAccount).transfer(withdrawalAmount);
		
		ResolveAuction(auctionId, withdrawalAccount, withdrawalAmount);
	}

	function withdrawFee() onlyOwner public
	{
		require( feeValue > 0, "fee is empty" );

		uint256 tmpFeeGame = feeValue;
		feeValue = 0;
		
		payable(owner).transfer(tmpFeeGame);
	}
}