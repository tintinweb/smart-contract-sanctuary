// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./Ownable.sol";

contract auction is Context, Ownable {

	IERC721 public nftAddress;
	
	uint256 sellingIds = 0;
	uint256 auctionIds = 0;
	
	
	uint256[] private buytoken;
	
	struct SellingToken{
	    uint256 tokenId;
	    uint256 price;
	    address tokenowner;
	    address buyer;
	    bool    exists;
	}
	
	struct auctionDetails{
		uint256 min_price;
		uint256 start_date;
		uint256 end_date;
		uint256 tokenId;
		address tokenOwner;
		address highestBidder;
		uint256 highestBid;
		uint256 totalBids;
	}
	
	mapping (uint256 => auctionDetails) public auctin;
	mapping (uint256 => uint256) public tokenId_To_auctionId;
	mapping (address => mapping (uint256 => uint256)) public claim;
	mapping (uint256 => SellingToken)  public selltoken;
	mapping (uint256 => uint256) public tokenId_To_sellingId;

    event Buy (address indexed payer, uint tokenId, uint amount, uint time);
    event Sell(address indexed buyer, uint tokenId, uint price, uint time);
    event Bid (address indexed bidder, uint auctionId, uint amount, uint time);


	function initialize(address _nftAddress) public onlyOwner virtual returns(bool){
		require(_nftAddress != address(0));
		nftAddress = IERC721(_nftAddress);
		return true;
	}
	
	function auctions (uint256 _tokenId, uint256 _minPrice, uint256 _startTime, uint256 _endTime) public virtual returns(bool){
		require	(nftAddress.getApproved(_tokenId) == address(this), "Token Not Approved");
		require(nftAddress.ownerOf(_tokenId) == msg.sender, "You are not owner");
		require(_startTime < _endTime && _endTime > block.timestamp, "Check dates");
		auctionDetails memory auction_token;
		auction_token = auctionDetails({
			min_price  : _minPrice,
			start_date : _startTime,
			end_date   : _endTime,
			tokenId    : _tokenId,
			tokenOwner : msg.sender,
			highestBidder: address(0),
			highestBid   : 0,
			totalBids    : 0
		});
		auctionIds++;
		auctin[auctionIds] = auction_token;
		tokenId_To_auctionId[_tokenId] = auctionIds;
		nftAddress.transferFrom(msg.sender, address(this), _tokenId);
		return true;
	}
	
	function bid(uint256 auctionId) public payable{
		require (block.timestamp > auctin[auctionId].start_date,"Auction not started yet.");
		require (block.timestamp < auctin[auctionId].end_date,"Auction already ended.");
		require (msg.value > auctin[auctionId].highestBid, "Your bid is less");
		auctin[auctionId].highestBid = msg.value;
		auctin[auctionId].highestBidder = msg.sender;
		auctin[auctionId].totalBids++;
		claim[msg.sender][auctionId] = msg.value;
		emit Bid(msg.sender, auctionId, msg.value, block.timestamp);
	}
	
	function claims(uint256 auctionId) public {
		require (block.timestamp > auctin[auctionId].end_date,"Auction not ended yes");
		require (claim[msg.sender][auctionId] > 0,"No bid");
		if(auctin[auctionId].highestBidder == msg.sender){
			nftAddress.transferFrom(auctin[auctionId].tokenOwner, auctin[auctionId].highestBidder, auctin[auctionId].tokenId);
		}else{
			payable(_msgSender()).transfer(claim[msg.sender][auctionId]);
		}
	}
	
	function buy(uint256 _tokenId) public payable  {
        require(msg.value >= selltoken[tokenId_To_sellingId[_tokenId]].price, "Your amount is less");
        require(selltoken[tokenId_To_sellingId[_tokenId]].exists,"TokenId not exist");
        require(selltoken[tokenId_To_sellingId[_tokenId]].buyer == address(0), "Token is already sold");
        nftAddress.transferFrom(address(this), msg.sender, _tokenId);
        payable(selltoken[tokenId_To_sellingId[_tokenId]].tokenowner).transfer(msg.value);
        selltoken[tokenId_To_sellingId[_tokenId]].buyer = msg.sender;
        buytoken.push(_tokenId);
        selltoken[tokenId_To_sellingId[_tokenId]].exists = false;
        emit Buy(msg.sender, _tokenId, msg.value, block.timestamp);
    }
    
	function sell(uint256 _tokenId, uint256 _price) public virtual {
	    require (msg.sender == nftAddress.ownerOf(_tokenId),"You are not owner");
	    require	(nftAddress.getApproved(_tokenId) == address(this), "Token not approved");
	    SellingToken memory sellToken;
    	sellToken = SellingToken({
    	   tokenId : _tokenId,
    	   price   : _price,
    	   tokenowner : msg.sender,
    	   buyer   : address(0),
    	   exists  : true
    	});
    	sellingIds++;
	   	selltoken[sellingIds] = sellToken;
	   	tokenId_To_sellingId[_tokenId] = sellingIds;
        nftAddress.transferFrom(msg.sender, address(this), _tokenId);
	    emit Sell(msg.sender, _tokenId, _price, block.timestamp);
	}
	
	function cancelSell(uint256 _tokenId) public virtual {
	     require(selltoken[tokenId_To_sellingId[_tokenId]].exists,"TokenId not exist");
	     nftAddress.transferFrom(address(this), msg.sender, _tokenId);
	     delete selltoken[tokenId_To_sellingId[_tokenId]];
	}

    
}