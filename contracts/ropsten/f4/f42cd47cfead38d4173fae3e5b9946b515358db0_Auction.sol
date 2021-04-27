// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./Counters.sol";
import "./Context.sol";

contract Auction is Context {
	using Counters for Counters.Counter;
	Counters.Counter private _auctionIds;
	
	Counters.Counter private _sellingIds;

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
	mapping (uint256 => uint256) public tokenprice;
	mapping (address => mapping (uint256 => uint256)) public claimed;

	uint256[] buytoken;
	
	struct SellingToken{
	    uint256 _tokenId;
	    bool exists;
	}
	mapping (uint256 => SellingToken)  public selltoken;
	mapping (uint256 => uint256) public tokenId_To_sellingId;

    event Buy_event(address indexed payer, uint tokenId, uint amount, uint time);
    event Sell_event(address indexed buyer, uint tokenId, uint price, uint time);
    
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
	
	function buyToken(uint256 _tokenId) public payable  {
        require(msg.value >= tokenprice[_tokenId], "Less Amount");
        address tokenSeller = nftAddress.ownerOf(_tokenId);
        nftAddress.safeTransferFrom(tokenSeller, msg.sender, _tokenId);
        payable(_msgSender()).transfer(msg.value);
        buytoken.push(_tokenId);
        emit Buy_event(msg.sender, _tokenId, msg.value, block.timestamp);
    }
    

	function sell(uint256 _tokenId, uint256 _price) public virtual {
	    require(msg.sender == nftAddress.ownerOf(_tokenId),"You are not owner");
	    require	(nftAddress.getApproved(_tokenId) == address(this), "Token Not Approved");
	    tokenprice[_tokenId] = _price;
	    SellingToken memory sellToken;
    	sellToken = SellingToken({
    	       _tokenId : _tokenId,
    	        exists   : true
    	});
	   	_sellingIds.increment();
	   	selltoken[_sellingIds.current()] = sellToken;
	   	tokenId_To_sellingId[_tokenId] = _sellingIds.current();
	    emit Sell_event(address(this), _tokenId, _price, block.timestamp);
	}

	
	function gettotalbuytokens() public view virtual returns(uint256){
	    return buytoken.length;
	}
	
    
    function cancelSell(uint256 _tokenId) public  virtual returns(bool){
        uint256 id = tokenId_To_sellingId[_tokenId];
        require(selltoken[id].exists,"Id not Exist");
        delete selltoken[id];
        return true;
    }

}