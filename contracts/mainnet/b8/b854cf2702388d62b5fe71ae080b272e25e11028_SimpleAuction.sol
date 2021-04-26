/**
 *Submitted for verification at Etherscan.io on 2021-04-26
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.1;

/*
VERSION DATE: 17/03/2021
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

contract SimpleAuction is Owned
{
	struct Auction
	{
        address seller;
		address tokenAddr;
		uint tokenId;
		uint beginPrice;
		uint minIncrement;
		uint32 startTime;
		uint32 endTime;
		uint highestBindingBid;
		address highestBidder;
    }

	uint public iterAuction = 0;
	mapping(uint256 => Auction) idAuction;						
	mapping(address => mapping(uint => uint)) addrAuction;  		// tokenAddr => tokenId => idAuction
	mapping(uint256 => mapping(address => uint256)) fundsByBidder;	// idAuction => addressUser => bid
	
	event CreateAuction(uint auctionId, address tokenAddr, uint tokenId);
	event Bid(uint auctionId, address bidder, uint addedBid, uint fullBid);
	event LogWithdrawal(uint auctionId, address withdrawalAccount, uint amount);
	
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
			beginPrice,
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
		
		addrAuction[tokenAddr][tokenId] = 0;
	}

	function getUserBid(uint256 auctionId, address user) public view returns (uint)
    {
		require(auctionId > 0 && auctionId <= iterAuction, "wrong auctionId");
        return fundsByBidder[auctionId][user];
    }

	function placeBid(uint256 auctionId) public payable
	{
		require(auctionId > 0 && auctionId <= iterAuction, "wrong auctionId");
		Auction storage auction = idAuction[auctionId];
		
		require( timenow() >= auction.startTime, "Auction hasn't started yet" );
		require( timenow() <= auction.endTime, "Auction already ended" );
		
		require(msg.sender != auction.seller, "bidder equal owner");
		
		require(msg.value > 0, "null price" );

		uint newBid = fundsByBidder[auctionId][msg.sender] + msg.value;
		require(newBid >= auction.highestBindingBid + auction.minIncrement, "not overbid" );

		fundsByBidder[auctionId][msg.sender] = newBid;

		auction.highestBindingBid = newBid;
		auction.highestBidder = msg.sender;	

		emit Bid(auctionId, msg.sender, msg.value, newBid);
	}

	function getAuction(uint256 auctionId) public view returns
    (
        address seller,
		address tokenAddr,
		uint tokenId,
        uint beginPrice,
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
		beginPrice = auction.beginPrice;
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

	function withdraw(uint256 auctionId) public
    {
		require(auctionId > 0 && auctionId <= iterAuction, "wrong auctionId");
		Auction storage auction = idAuction[auctionId];
		
		require( timenow() > auction.endTime, "Auction hasn't ended yet" );
		
		address withdrawalAccount;
        uint withdrawalAmount;
		
		TokenAddress ta = TokenAddress(auction.tokenAddr);
		
		bool sendToken = false;
		if (msg.sender == auction.seller || msg.sender == auction.highestBidder)
		{
			withdrawalAccount = auction.seller;
			withdrawalAmount = fundsByBidder[auctionId][auction.highestBidder];

			if( ta.ownerOf(auction.tokenId) == auction.seller && ta.getApproved(auction.tokenId) == address(this) )
			{
				sendToken = true;
				uint curFee = withdrawalAmount * feePercent / 100;
				feeValue = feeValue + curFee;
				withdrawalAmount = withdrawalAmount - curFee;
			}
			else
			{
				withdrawalAccount = auction.highestBidder;
			}
			
			fundsByBidder[auctionId][auction.highestBidder] = 0;
			addrAuction[auction.tokenAddr][auction.tokenId] = 0;
		}
		else
		{
            withdrawalAccount = msg.sender;
			withdrawalAmount = fundsByBidder[auctionId][withdrawalAccount];
			fundsByBidder[auctionId][withdrawalAccount] = 0;
		}
		
		require(withdrawalAmount != 0, "withdrawalAmount is zero");

		if (sendToken)
		{
			ta.transferFrom(auction.seller, auction.highestBidder, auction.tokenId);
		}

		payable(withdrawalAccount).transfer(withdrawalAmount);

		LogWithdrawal(auctionId, withdrawalAccount, withdrawalAmount);
	}

	function withdrawFee() onlyOwner public
	{
		require( feeValue > 0, "fee is empty" );

		uint256 tmpFeeGame = feeValue;
		feeValue = 0;
		
		payable(owner).transfer(tmpFeeGame);
	}
}