// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./Ownable.sol";

contract Auction is Context, Ownable {

	IERC721 public nftAddress;
	
	uint256 sellingIds = 0;
	uint256 auctionIds = 0;
	
	struct SellingToken{
	    uint256 tokenId;
	    uint256 price;
	    address tokenOwner;
	    address buyer;
	    bool    exists;
	}
	
	struct AuctionToken{
	    uint256 tokenId;
	    uint256 price;
	    address tokenOwner;
	    uint256 startTime;
	    uint256 endTime;
	    address highestBidder;
		uint256 highestBid;
		uint256 totalBids;
		bool    exists;
	}
	
	mapping (uint256 => AuctionToken)  public auctiontoken;
	mapping (uint256 => uint256) public tokenId_To_auctionId;
	mapping (address => mapping (uint256 => uint256)) public claim;
	
	mapping (uint256 => SellingToken)  public selltoken;
	mapping (uint256 => uint256) public tokenId_To_sellingId;

    event Buy  (address indexed _buyer,  uint _tokenId, uint _price, uint _time);
    event Sell (address indexed _seller, uint _tokenId, uint _price, uint _time);
    event Bid  (address indexed _bidder, uint _auctionId, uint _price, uint _time);
    event Auctin (address indexed _tokenOwner, uint _tokenId, uint256 _price, uint256 _startTime, uint256 _endTime);
    


	function initialize(address _nftAddress) public onlyOwner virtual returns(bool){
		require(_nftAddress != address(0));
		nftAddress = IERC721(_nftAddress);
		return true;
	}
	
	function auction(uint256 _tokenId, uint256 _price, uint256 _startTime, uint256 _endTime) public {
	    require (msg.sender == nftAddress.ownerOf(_tokenId), "You are not owner");
	    require (nftAddress.getApproved(_tokenId) == address(this), "Token not approved");
	    require (_startTime < _endTime && _endTime > block.timestamp, "Check Time");
	    AuctionToken memory auctionToken;
	    auctionToken = AuctionToken({
	        tokenId       : _tokenId,
	        price         : _price,
	        tokenOwner    : msg.sender,
	        startTime     : _startTime,
	        endTime       : _endTime,
	        highestBidder : address(0),
			highestBid    : 0,
			totalBids     : 0,
			exists        : true
	    });
	    auctionIds++;
	    auctiontoken[auctionIds] = auctionToken;
	    tokenId_To_auctionId[_tokenId] = auctionIds;
	    nftAddress.transferFrom(msg.sender, address(this), _tokenId);
	    emit Auctin (msg.sender, _tokenId, _price, _startTime, _endTime);
	}
	
	function bid(uint256 _auctionId) public payable{
	    require(block.timestamp > auctiontoken[_auctionId].startTime,"Auction not started yet");
	    require(block.timestamp < auctiontoken[_auctionId].endTime,"Auction is over");
	    // If this is the first bid, ensure it's >= the reserve price.
        require(msg.value >= auctiontoken[_auctionId].price, "Bid must be at least the reserve price");
        // Bid must be greater than last bid.
	    require(msg.value > auctiontoken[_auctionId].highestBid, "Bid amount too low");
	    auctiontoken[_auctionId].highestBidder = msg.sender;
	    auctiontoken[_auctionId].highestBid    = msg.value;
	    auctiontoken[_auctionId].totalBids++;
	    claim[msg.sender][_auctionId] += msg.value;
	    emit Bid(msg.sender, _auctionId, msg.value, block.timestamp);
	}
	
	function claims(uint256 _auctionId) public {
	    require (block.timestamp > auctiontoken[_auctionId].endTime,"Auction not ended yes");
		require (claim[msg.sender][_auctionId] > 0,"No bid");
		if(auctiontoken[_auctionId].highestBidder == msg.sender){
		    nftAddress.transferFrom(address(this), msg.sender, auctiontoken[_auctionId].tokenId);
		    if(claim[msg.sender][_auctionId] > auctiontoken[_auctionId].highestBid){
		        uint256 amount = claim[msg.sender][_auctionId] - auctiontoken[_auctionId].highestBid;
		        payable(msg.sender).transfer(amount);
		    }
		    auctiontoken[_auctionId].exists = false;
		}	
		else{
		    payable(msg.sender).transfer(claim[msg.sender][_auctionId]);
		    claim[msg.sender][_auctionId] = 0;
		}
	}
	
	function buy(uint256 _tokenId) public payable  {
		require(msg.value >= selltoken[tokenId_To_sellingId[_tokenId]].price, "Your amount is less");
		require(selltoken[tokenId_To_sellingId[_tokenId]].exists,"TokenId not exist");
		require(selltoken[tokenId_To_sellingId[_tokenId]].buyer == address(0), "Token is already sold");
		nftAddress.transferFrom(address(this), msg.sender, _tokenId);
		payable(selltoken[tokenId_To_sellingId[_tokenId]].tokenOwner).transfer(msg.value);
		selltoken[tokenId_To_sellingId[_tokenId]].buyer = msg.sender;
		selltoken[tokenId_To_sellingId[_tokenId]].exists = false;
		emit Buy(msg.sender, _tokenId, msg.value, block.timestamp);
    }
    
	function sell(uint256 _tokenId, uint256 _price) public {
	    require (msg.sender == nftAddress.ownerOf(_tokenId),"You are not owner");
	    require	(nftAddress.getApproved(_tokenId) == address(this), "Token not approved");
	    SellingToken memory sellToken;
    	sellToken = SellingToken({
    		   tokenId    : _tokenId,
    		   price      : _price,
    		   tokenOwner : msg.sender,
    		   buyer      : address(0),
    		   exists     : true
    	 });
    	 sellingIds++;
	     selltoken[sellingIds] = sellToken;
	     tokenId_To_sellingId[_tokenId] = sellingIds;
         nftAddress.transferFrom(msg.sender, address(this), _tokenId);
	     emit Sell(msg.sender, _tokenId, _price, block.timestamp);
	}   
	
	function cancelSell(uint256 _tokenId) public {
	     require(msg.sender == selltoken[tokenId_To_sellingId[_tokenId]].tokenOwner, "You are not owner");
	     require(selltoken[tokenId_To_sellingId[_tokenId]].exists,"TokenId not exist");
	     nftAddress.transferFrom(address(this), msg.sender, _tokenId);
	     delete selltoken[tokenId_To_sellingId[_tokenId]];
	}
	
	function cancelAuction(uint256 _tokenId) public {
	    require(msg.sender == auctiontoken[tokenId_To_auctionId[_tokenId]].tokenOwner, "You are not owner");
	    require(auctiontoken[tokenId_To_auctionId[_tokenId]].endTime > block.timestamp,"You can not cancel this auction");
	    nftAddress.transferFrom(address(this), msg.sender, _tokenId);
	    delete auctiontoken[tokenId_To_auctionId[_tokenId]];
	}
}