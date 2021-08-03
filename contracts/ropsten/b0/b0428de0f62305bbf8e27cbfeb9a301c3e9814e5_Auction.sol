// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./Ownable.sol";

contract Auction is Context, Ownable {
	
	// The NFT token we are selling
	IERC721 public nft_token;
	
	// Represents an auction on an NFT
	struct AuctionToken{
	    // Price (in wei) at beginning of auction
	    uint256 price;
	    // Time (in seconds) when auction started
	    uint256 startTime;
	    // Time (in seconds) when auction started
	    uint256 endTime;
	    // Address of highestbidder
	    address highestBidder;
	    // Highest bid amount
	    uint256 highestBid;
	    // Total number of bids
	    uint256 totalBids;
	}
	
	// Mapping token ID to their corresponding auction.
	mapping (uint256 => AuctionToken)  public auction;
	// Mapping from addresss to token ID for claim.
	mapping (address => mapping (uint256 => uint256)) public pending_claim;
	// Mapping from token ID to tokenprice
	mapping (uint256 => uint256) public token_price;
	// Mapping from token ID to tokenowners
        mapping (uint256 => address) public token_owner;
	
	
    	event Sell (address indexed _seller, uint _tokenId, uint _price, uint _time);   
	event SellCancelled    (address indexed _seller, uint _tokenId, uint _time);
    	event Buy  (address indexed _buyer,  uint _tokenId, address _seller, uint _price, uint _time);
	
    	event AuctionCreated (address indexed _seller, uint _tokenId, uint256 _price, uint256 _startTime, uint256 _endTime);
	event Bid  (address indexed _bidder, uint _tokenId, uint _price, uint _time);	
    	event AuctionCancelled (address indexed _seller, uint _tokenId, uint _time);
        
	///@dev Initialize the nft token contract address.
	function initialize(address _nftToken) public onlyOwner virtual returns(bool){
	    require(_nftToken != address(0));
	    nft_token = IERC721(_nftToken);
	    return true;
	}
	 /// @dev Creates and begins a new auction.
         /// @param _tokenId - ID of token to auction, sender must be owner.
         /// @param _price - Price of token (in wei) at beginning of auction.
         /// @param _startTime - Start time of auction.
         /// @param _endTime - End time of auction.
	function createAuction(uint256 _tokenId, uint256 _price, uint256 _startTime, uint256 _endTime) public {
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
    		totalBids     : 0
	    });
	    token_owner[_tokenId] = msg.sender;
	    auction[_tokenId] = auctionToken;
	    nft_token.transferFrom(msg.sender, address(this), _tokenId);
	    emit AuctionCreated(msg.sender, _tokenId, _price, _startTime, _endTime);
	}
	
	/// @dev Bids on an open auction.
	/// @param _tokenId - ID of token to bid on.
	function bid(uint256 _tokenId) public payable{
	    require(block.timestamp > auction[_tokenId].startTime,"Auction not started yet");
	    require(block.timestamp < auction[_tokenId].endTime,"Auction is over");
	    // The first bid, ensure it's >= the reserve price.
            require(msg.value >= auction[_tokenId].price, "Bid must be at least the reserve price");
            // Bid must be greater than last bid.
	    require(msg.value > auction[_tokenId].highestBid, "Bid amount too low");
	    auction[_tokenId].highestBidder = msg.sender;
	    auction[_tokenId].highestBid    = msg.value;
	    auction[_tokenId].totalBids++;
	    pending_claim[msg.sender][_tokenId] += msg.value;
	    emit Bid(msg.sender, _tokenId, msg.value, block.timestamp);
	}
	
	/// @dev Create claim after auction ends.
	/// Transfer NFT to auction winner address.
	/// Transfer funds to seller address.
	/// @param _tokenId - ID of NFT.
	function claim(uint256 _tokenId) public {
	    require(block.timestamp > auction[_tokenId].endTime,"Auction not ended yes");
	    require(pending_claim[msg.sender][_tokenId] > 0,"No bid found");
	    if(auction[_tokenId].highestBidder == msg.sender){
    		nft_token.transferFrom(address(this), msg.sender, _tokenId);
		payable(token_owner[_tokenId]).transfer(pending_claim[msg.sender][_tokenId]);
	    }	
	    else{
    		payable(msg.sender).transfer(pending_claim[msg.sender][_tokenId]);
    		pending_claim[msg.sender][_tokenId] = 0;
	    }
	}
	
	/// @dev Buy from open sell.
	/// Transfer NFT ownership to buyer address.
	/// @param _tokenId - ID of NFT on buy.
	function buy(uint256 _tokenId) public payable  {
	     require(msg.value >= token_price[_tokenId], "Your amount is less");
	     require(token_owner[_tokenId]!= address(0),"Token not for sell");
	     nft_token.transferFrom(address(this), msg.sender, _tokenId);
	     payable(token_owner[_tokenId]).transfer(msg.value);
	     emit Buy(msg.sender, _tokenId, token_owner[_tokenId], msg.value, block.timestamp);
    	}
        
	/// @dev Creates a new sell.
	/// Transfer NFT ownership to this contract.
	/// @param _tokenId - ID of NFT on sell.
	/// @param _price   - Seller set the price (in eth) of token.
	function sell(uint256 _tokenId, uint256 _price) public {
	     require(msg.sender == nft_token.ownerOf(_tokenId),"You are not owner");
	     require(nft_token.getApproved(_tokenId) == address(this), "Token not approved");
	     token_price[_tokenId] = _price;
             nft_token.transferFrom(msg.sender, address(this), _tokenId);
             token_owner[_tokenId] = msg.sender;
	     emit Sell(msg.sender, _tokenId, _price, block.timestamp);
	}   
	
	/// @dev Removes token from the list of open sell.
	/// Returns the NFT to original owner.
	/// @param _tokenId - ID of NFT on sell.
	function cancelSell(uint256 _tokenId) public {
	     require(msg.sender == token_owner[_tokenId], "You are not owner");
	     nft_token.transferFrom(address(this), msg.sender, _tokenId);
	     delete token_owner[_tokenId];
	     emit SellCancelled(msg.sender, _tokenId, block.timestamp);
	}
	
	/// @dev Removes an auction from the list of open auctions.
	/// Returns the NFT to original owner.
	/// @param _tokenId - ID of NFT on auction.
	function cancelAuction(uint256 _tokenId) public {
	    require(msg.sender == token_owner[_tokenId], "You are not owner");
	    require(auction[_tokenId].endTime > block.timestamp,"Can't cancel this auction");
	    nft_token.transferFrom(address(this), msg.sender, _tokenId);
	    delete auction[_tokenId];
	    emit AuctionCancelled(msg.sender, _tokenId, block.timestamp);
	}
}