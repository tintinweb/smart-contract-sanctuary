// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./Ownable.sol";

contract Auction is Context, Ownable {

	IERC721 public nft_token;
	
	uint256 auction_id = 0;
	
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
	
	mapping (uint256 => AuctionToken)  public auction_token;
	mapping (uint256 => uint256) public tokenId_To_auctionId;
	mapping (address => mapping (uint256 => uint256)) public pending_claim;
	
	mapping (uint256 => uint256) public tokenprice;

    uint256[] public Sell_token;
    
    
    event Sell (address indexed _seller, uint _tokenId, uint _price, uint _time);
    event Bid  (address indexed _bidder, uint _auctionId, uint _price, uint _time);
    event CancelSell (address indexed _seller, uint _tokenId, uint _time);
    event CancelAuction (address indexed _tokenOwner, uint _tokenId, uint _time);
    event Buy    (address indexed _buyer,  uint _tokenId, address _seller, uint _price, uint _time);
    event Auctin (address indexed _tokenOwner, uint _tokenId, uint256 _price, uint256 _startTime, uint256 _endTime);
    
	function initialize(address _nftAddress) public onlyOwner virtual returns(bool){
	    require(_nftAddress != address(0));
	    nft_token = IERC721(_nftAddress);
	    return true;
	}
	
	function auction(uint256 _tokenId, uint256 _price, uint256 _startTime, uint256 _endTime) public {
	    require(msg.sender == nft_token.ownerOf(_tokenId), "You are not owner");
	    require(nft_token.getApproved(_tokenId) == address(this), "Token not approved");
	    require(_startTime < _endTime && _endTime > block.timestamp, "Check Time");
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
	    auction_id++;
	    auction_token[auction_id] = auctionToken;
	    tokenId_To_auctionId[_tokenId] = auction_id;
	    nft_token.transferFrom(msg.sender, address(this), _tokenId);
	    emit Auctin(msg.sender, _tokenId, _price, _startTime, _endTime);
	}
	
	function bid(uint256 _auctionId) public payable{
	    require(block.timestamp > auction_token[_auctionId].startTime,"Auction not started yet");
	    require(block.timestamp < auction_token[_auctionId].endTime,"Auction is over");
	    // If this is the first bid, ensure it's >= the reserve price.
        require(msg.value >= auction_token[_auctionId].price, "Bid must be at least the reserve price");
        // Bid must be greater than last bid.
	    require(msg.value > auction_token[_auctionId].highestBid, "Bid amount too low");
	    auction_token[_auctionId].highestBidder = msg.sender;
	    auction_token[_auctionId].highestBid    = msg.value;
	    auction_token[_auctionId].totalBids++;
	    pending_claim[msg.sender][_auctionId] += msg.value;
	    emit Bid(msg.sender, _auctionId, msg.value, block.timestamp);
	}
	
	function claim(uint256 _auctionId) public {
	    require(block.timestamp > auction_token[_auctionId].endTime,"Auction not ended yes");
	    require(pending_claim[msg.sender][_auctionId] > 0,"No bid found");
	    require(auction_token[_auctionId].exists,"Token not exist");
	    if(auction_token[_auctionId].highestBidder == msg.sender){
    		nft_token.transferFrom(address(this), msg.sender, auction_token[_auctionId].tokenId);
    		auction_token[_auctionId].exists = false;
	    }	
	    else{
    		payable(msg.sender).transfer(pending_claim[msg.sender][_auctionId]);
    		pending_claim[msg.sender][_auctionId] = 0;
	    }
	}
	
	function buy(uint256 _tokenId) public payable  {
	     require(msg.value >= tokenprice[_tokenId], "Your amount is less");
	     nft_token.transferFrom(address(this), msg.sender, _tokenId);
	     address tokenSeller = nft_token.ownerOf(_tokenId);
	     payable(tokenSeller).transfer(msg.value);
	     emit Buy(msg.sender, _tokenId, tokenSeller, msg.value, block.timestamp);
    }
    
	function sell(uint256 _tokenId, uint256 _price) public {
	     require(msg.sender == nft_token.ownerOf(_tokenId),"You are not owner");
	     require(nft_token.getApproved(_tokenId) == address(this), "Token not approved");
	     tokenprice[_tokenId] = _price;
         nft_token.transferFrom(msg.sender, address(this), _tokenId);
         Sell_token.push(_tokenId);
	     emit Sell(msg.sender, _tokenId, _price, block.timestamp);
	}   
	
	function cancelSell(uint256 _tokenId) public {
	     require(msg.sender == nft_token.ownerOf(_tokenId), "You are not owner");
	     nft_token.transferFrom(address(this), msg.sender, _tokenId);
	     delete Sell_token[_tokenId];
	     emit CancelSell(msg.sender, _tokenId, block.timestamp);
	}
	
	function cancelAuction(uint256 _tokenId) public {
	    require(msg.sender == auction_token[tokenId_To_auctionId[_tokenId]].tokenOwner, "You are not owner");
	    require(auction_token[tokenId_To_auctionId[_tokenId]].endTime > block.timestamp,"Can't cancel this auction");
	    nft_token.transferFrom(address(this), msg.sender, _tokenId);
	    delete auction_token[tokenId_To_auctionId[_tokenId]];
	    emit CancelAuction(msg.sender, _tokenId, block.timestamp);
	}
}