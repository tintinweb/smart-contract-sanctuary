// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./Ownable.sol";

contract Auction is Context, Ownable {

	IERC721 public nft_token;
	
	
	struct AuctionToken{
	    uint256 price;
	    uint256 startTime;
	    uint256 endTime;
	    address highestBidder;
	    uint256 highestBid;
	    uint256 totalBids;
	    bool    exists;
	}
	
	mapping (uint256 => AuctionToken)  public auction_token;
	mapping (address => mapping (uint256 => uint256)) public pending_claim;
	
	mapping (uint256 => uint256) public token_price;
    mapping (uint256 => address) public token_owner;
	
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
	        price         : _price,
	        startTime     : _startTime,
	        endTime       : _endTime,
	        highestBidder : address(0),
    		highestBid    : 0,
    		totalBids     : 0,
    		exists        : true
	    });
	    token_owner[_tokenId] = msg.sender;
	    auction_token[_tokenId] = auctionToken;
	    nft_token.transferFrom(msg.sender, address(this), _tokenId);
	    emit Auctin(msg.sender, _tokenId, _price, _startTime, _endTime);
	}
	
	function bid(uint256 _tokenId) public payable{
	    require(block.timestamp > auction_token[_tokenId].startTime,"Auction not started yet");
	    require(block.timestamp < auction_token[_tokenId].endTime,"Auction is over");
	    // If this is the first bid, ensure it's >= the reserve price.
        require(msg.value >= auction_token[_tokenId].price, "Bid must be at least the reserve price");
        // Bid must be greater than last bid.
	    require(msg.value > auction_token[_tokenId].highestBid, "Bid amount too low");
	    auction_token[_tokenId].highestBidder = msg.sender;
	    auction_token[_tokenId].highestBid    = msg.value;
	    auction_token[_tokenId].totalBids++;
	    pending_claim[msg.sender][_tokenId] += msg.value;
	    emit Bid(msg.sender, _tokenId, msg.value, block.timestamp);
	}
	
	function claims(uint256 _tokenId) public {
	    require(block.timestamp > auction_token[_tokenId].endTime,"Auction not ended yes");
	    require(pending_claim[msg.sender][_tokenId] > 0,"No bid found");
	    require(auction_token[_tokenId].exists,"Token not exist");
	    if(auction_token[_tokenId].highestBidder == msg.sender){
    		nft_token.transferFrom(address(this), msg.sender, _tokenId);
    		auction_token[_tokenId].exists = false;
	    }	
	    else{
    		payable(msg.sender).transfer(pending_claim[msg.sender][_tokenId]);
    		pending_claim[msg.sender][_tokenId] = 0;
	    }
	}
	
	function buy(uint256 _tokenId) public payable  {
	     require(msg.value >= token_price[_tokenId], "Your amount is less");
	     require(token_owner[_tokenId]!= address(0),"Token not for sell");
	     nft_token.transferFrom(address(this), msg.sender, _tokenId);
	     payable(token_owner[_tokenId]).transfer(msg.value);
	     emit Buy(msg.sender, _tokenId, token_owner[_tokenId], msg.value, block.timestamp);
    }
    
	function sell(uint256 _tokenId, uint256 _price) public {
	     require(msg.sender == nft_token.ownerOf(_tokenId),"You are not owner");
	     require(nft_token.getApproved(_tokenId) == address(this), "Token not approved");
	     token_price[_tokenId] = _price;
         nft_token.transferFrom(msg.sender, address(this), _tokenId);
         token_owner[_tokenId] = msg.sender;
	     emit Sell(msg.sender, _tokenId, _price, block.timestamp);
	}   
	
	function cancelSell(uint256 _tokenId) public {
	     require(msg.sender == token_owner[_tokenId], "You are not owner");
	     nft_token.transferFrom(address(this), msg.sender, _tokenId);
	     delete token_owner[_tokenId];
	     emit CancelSell(msg.sender, _tokenId, block.timestamp);
	}
	
	function cancelAuction(uint256 _tokenId) public {
	    require(msg.sender ==  token_owner[_tokenId], "You are not owner");
	    require(auction_token[_tokenId].endTime > block.timestamp,"Can't cancel this auction");
	    nft_token.transferFrom(address(this), msg.sender, _tokenId);
	    delete auction_token[_tokenId];
	    emit CancelAuction(msg.sender, _tokenId, block.timestamp);
	}
}