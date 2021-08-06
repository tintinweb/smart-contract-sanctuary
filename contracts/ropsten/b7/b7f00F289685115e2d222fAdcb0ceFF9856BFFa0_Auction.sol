// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract Auction is Ownable {
	 using SafeMath for uint256;
	// The NFT token we are selling
	IERC721 private nft_token;
	
	// Admin Address
	address admin;
	
	
	// Represents an auction on an NFT
	struct AuctionDetails{
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
	mapping (uint256 => AuctionDetails) private auction;
	// Mapping from addresss to token ID for claim.
	mapping (address => mapping (uint256 => uint256)) public pending_claim;
	// Mapping from token ID to tokenprice
	mapping (uint256 => uint256) private token_price;
	// Mapping from token ID to tokenseller
    mapping (uint256 => address) private token_seller;
    
    uint256 sell_token_fee;
    uint256 auction_token_fee;
    
	
	
    event Sell (address indexed _seller, uint _tokenId, uint _price, uint _time);   
	event SellCancelled (address indexed _seller, uint _tokenId, uint _time);
    event Buy  (address indexed _buyer,  uint _tokenId, address _seller, uint _price, uint _time);
	
    event AuctionCreated (address indexed _seller, uint _tokenId, uint256 _price, uint256 _startTime, uint256 _endTime);
	event Bid  (address indexed _bidder, uint _tokenId, uint _price, uint _time);	
    event AuctionCancelled (address indexed _seller, uint _tokenId, uint _time);
        
	/// @dev Initialize the nft token contract address.
	function initialize(address _nftToken) public onlyOwner virtual returns(bool){
	    require(_nftToken != address(0));
	    nft_token = IERC721(_nftToken);
	    return true;
	}
	
	/// @dev Returns the nft token contract address.
	function getNFTToken() public view returns(IERC721){
	    return nft_token;
	}
	
	/// @dev Set the beneficiary address.
	/// @param _owner - beneficiary addess.
	function beneficiary(address _owner) public onlyOwner {
	    admin = _owner;
	}
	
	/// @dev Contract owner set the token fee percent which is for sell.
	/// @param _tokenFee - Token fee.
	function setTokenFeePercentForSell(uint256 _tokenFee) public onlyOwner {
	     sell_token_fee = _tokenFee;
	}
	
	/// @dev Contract owner set the token fee percent which is for auction.
	/// @param _tokenFee - Token fee.
	function setTokenFeePercentForAuction(uint256 _tokenFee) public onlyOwner {
	     auction_token_fee = _tokenFee;
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
	    AuctionDetails memory auctionToken;
	    auctionToken = AuctionDetails({
	        price         : _price,
	        startTime     : _startTime,
	        endTime       : _endTime,
	        highestBidder : address(0),
    		highestBid    : 0,
    		totalBids     : 0
	    });
	    token_seller[_tokenId] = msg.sender;
	    auction[_tokenId] = auctionToken;
	    nft_token.transferFrom(msg.sender, address(this), _tokenId);
	    emit AuctionCreated(msg.sender, _tokenId, _price, _startTime, _endTime);
	}
	
	/// @dev Bids on an open auction.
	/// @param _tokenId - ID of token to bid on.
	function bid(uint256 _tokenId) public payable{
	    require(block.timestamp > auction[_tokenId].startTime, "Auction not started yet");
	    require(block.timestamp < auction[_tokenId].endTime, "Auction is over");
	    // The first bid, ensure it's >= the reserve price.
        require(msg.value >= auction[_tokenId].price, "Bid must be at least the reserve price");
        // Bid must be greater than last bid.
	    require(msg.value > auction[_tokenId].highestBid, "Bid amount too low");
	    pending_claim[msg.sender][_tokenId] += msg.value;
	    auction[_tokenId].highestBidder = msg.sender;
	    auction[_tokenId].highestBid    = pending_claim[msg.sender][_tokenId];
	    auction[_tokenId].totalBids++;
	    emit Bid(msg.sender, _tokenId, msg.value, block.timestamp);
	}
	
	/// @dev Create claim after auction ends.
	/// Transfer NFT to auction winner address.
	/// @param _tokenId - ID of NFT.
	function claim(uint256 _tokenId) public {
	    require(block.timestamp > auction[_tokenId].endTime, "Auction not ended yet");
	    require(auction[_tokenId].highestBidder == msg.sender, "Not a winner");
    	nft_token.transferFrom(address(this), msg.sender, _tokenId);
	}
	
	/// @dev Seller and Bidders (not win in auction) Withdraw their funds.
	/// @param _tokenId - ID of NFT.
	function withdraw(uint256 _tokenId) public {
	    require(block.timestamp > auction[_tokenId].endTime, "Auction not ended yet");
	    if(msg.sender == token_seller[_tokenId]){
	        payable(msg.sender).transfer(auction[_tokenId].highestBid);
	        pending_claim[auction[_tokenId].highestBidder][_tokenId] = 0;
	    }
	    else{
	        payable(msg.sender).transfer(pending_claim[msg.sender][_tokenId]);
    		pending_claim[msg.sender][_tokenId] = 0;
	    }
	}
	
	/// @dev Returns auction info for an NFT on auction.
    /// @param _tokenId - ID of NFT on auction.
	function getAuction(uint256 _tokenId) public view virtual returns(uint256, uint256, uint256, address, uint256, uint256){
		return (auction[_tokenId].price,
			auction[_tokenId].startTime,
			auction[_tokenId].endTime,
			auction[_tokenId].highestBidder,
			auction[_tokenId].highestBid,
			auction[_tokenId].totalBids
		);
	}
	
	/// @dev Returns sell NFT token price.
	/// @param _tokenId - ID of NFT.
	function getSellTokenPrice(uint256 _tokenId) public view returns(uint256){
	    return token_price[_tokenId];
	}
	
	/// @dev Buy from open sell.
	/// Transfer NFT ownership to buyer address.
	/// @param _tokenId - ID of NFT on buy.
	function buy(uint256 _tokenId) public payable  {
	     require(msg.value >= token_price[_tokenId], "Your amount is less");
	     require(token_seller[_tokenId]!= address(0),"Token not for sell");
	     nft_token.transferFrom(address(this), msg.sender, _tokenId);
	     payable(admin).transfer(msg.value.mul(sell_token_fee).div(100));
	     payable(token_seller[_tokenId]).transfer(msg.value.mul(100 - sell_token_fee).div(100));
	     emit Buy(msg.sender, _tokenId, token_seller[_tokenId], msg.value, block.timestamp);
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
         token_seller[_tokenId] = msg.sender;
	     emit Sell(msg.sender, _tokenId, _price, block.timestamp);
	}   
	
	/// @dev Removes token from the list of open sell.
	/// Returns the NFT to original owner.
	/// @param _tokenId - ID of NFT on sell.
	function cancelSell(uint256 _tokenId) public {
	     require(msg.sender == token_seller[_tokenId], "You are not owner");
	     nft_token.transferFrom(address(this), msg.sender, _tokenId);
	     delete token_seller[_tokenId];
	     emit SellCancelled(msg.sender, _tokenId, block.timestamp);
	}
	
	/// @dev Removes an auction from the list of open auctions.
	/// Returns the NFT to original owner.
	/// @param _tokenId - ID of NFT on auction.
	function cancelAuction(uint256 _tokenId) public {
	    require(msg.sender == token_seller[_tokenId], "You are not owner");
	    require(auction[_tokenId].endTime > block.timestamp,"Can't cancel this auction");
	    nft_token.transferFrom(address(this), msg.sender, _tokenId);
	    delete auction[_tokenId];
	    emit AuctionCancelled(msg.sender, _tokenId, block.timestamp);
	}
}