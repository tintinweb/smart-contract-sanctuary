// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./Counters.sol";
import "./Context.sol";

contract Auction is Context {
	using Counters for Counters.Counter;
	Counters.Counter private _auctionIds;

	IERC721 private nftAddress;

	struct AuctinDetails{
		uint256 min_price;
		uint256 start_date;
		uint256 end_date;
		uint256 tokenId;
		address tokenOwner;
		address highestBidder;
		uint256 highestBid;
	}
	mapping (uint256 => AuctinDetails) public auction;
	mapping (uint256 => uint256) public tokenId_To_auctionId;
	mapping (address => mapping (uint256 => uint256)) public claimed;

	function getAuction(uint256 auction_id) public view virtual returns(uint256, uint256, uint256, address, uint256){
		return (auction[auction_id].min_price,
			auction[auction_id].start_date,
			auction[auction_id].end_date,
			auction[auction_id].highestBidder,
			auction[auction_id].highestBid
		);
	}

	function Auctions (uint256 tokenId, uint256 min_price, uint256 start_date, uint256 end_date) public virtual returns(bool){
		require	(nftAddress.getApproved(tokenId) == address(this), "Token Not Approved");
		require(nftAddress.ownerOf(tokenId) == msg.sender, "You are not owner");
		require(start_date < end_date && end_date > block.timestamp, "Check dates");

		AuctinDetails memory auction_token;
		auction_token = AuctinDetails({
			min_price : min_price,
			start_date : start_date,
			end_date : end_date,
			tokenId : tokenId,
			tokenOwner : msg.sender,
			highestBidder: address(0),
			highestBid   : 0
		});

		_auctionIds.increment();
		auction[_auctionIds.current()] = auction_token;
		tokenId_To_auctionId[tokenId] = _auctionIds.current();

		return true;
	}

	function bid(uint256 auctionId) public payable{
		require (block.timestamp > auction[auctionId].start_date,"Not started yet");
		require (block.timestamp < auction[auctionId].end_date,"Auction ended");
		require (msg.value > auction[auctionId].highestBid, "Your bid is less");
		
		auction[auctionId].highestBid = msg.value;
		auction[auctionId].highestBidder = msg.sender;
		claimed[msg.sender][auctionId] = msg.value;
	}

	function claim(uint256 auctionId) public {
		require (block.timestamp > auction[auctionId].end_date,"Auction not ended yes");
		require (claimed[msg.sender][auctionId] > 0,"No bit");
		
		if(auction[auctionId].highestBidder == msg.sender){
			nftAddress.transferFrom(auction[auctionId].tokenOwner, auction[auctionId].highestBidder, auction[auctionId].tokenId);
		}else{
			payable(_msgSender()).transfer(claimed[msg.sender][auctionId]);
		}
	}

	function initialize(address _nftAddress) public virtual returns(bool){
		require(_nftAddress != address(0));
		nftAddress = IERC721(_nftAddress);
		return true;
		
	}
	
}