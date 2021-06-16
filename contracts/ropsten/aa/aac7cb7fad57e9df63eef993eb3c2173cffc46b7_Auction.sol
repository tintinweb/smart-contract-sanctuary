// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./Counters.sol";
import "./Context.sol";

contract Auction is Context {
	using Counters for Counters.Counter;
	Counters.Counter public auctionIds;

	IERC721 public nftAddress;

	struct AuctinDetails{
		uint256 min_price;
		uint256 start_date;
		uint256 end_date;
		uint256 tokenId;
		address tokenOwner;
		address highestBidder;
		uint256 highestBid;
		uint256 totalBids;
	}
	mapping (uint256 => AuctinDetails) public auction;
	mapping (uint256 => uint256) public tokenId_To_auctionId;
	mapping (uint256 => uint256) public tokenPrice;
	mapping (address => mapping (uint256 => uint256)) public claim;

	uint256[] private _buyToken;
	uint256[] private _sellToken;

    // Mapping from token id to position in the SellTokens array
    mapping(uint256 => uint256) private _allSellTokenIndex;

    event Buy(address indexed payer, uint tokenId, uint amount, uint time);
    event Sell(address indexed buyer, uint tokenId, uint price, uint time);
    

	function auctions (uint256 tokenId, uint256 min_price, uint256 start_date, uint256 end_date) public virtual returns(bool){
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
			highestBid   : 0,
			totalBids    : 0
		});
		auctionIds.increment();
		auction[auctionIds.current()] = auction_token;
		tokenId_To_auctionId[tokenId] = auctionIds.current();
		return true;
	}

	function bid(uint256 auctionId) public payable{
		require (block.timestamp > auction[auctionId].start_date,"Not started yet");
		require (block.timestamp < auction[auctionId].end_date,"Auction ended");
		require (msg.value > auction[auctionId].highestBid, "Your bid is less");
		auction[auctionId].highestBid = msg.value;
		auction[auctionId].highestBidder = msg.sender;
		auction[auctionId].totalBids++;
		claim[msg.sender][auctionId] = msg.value;
	}

	function claims(uint256 auctionId) public {
		require (block.timestamp > auction[auctionId].end_date,"Auction not ended yes");
		require (claim[msg.sender][auctionId] > 0,"No bit");
		if(auction[auctionId].highestBidder == msg.sender){
			nftAddress.transferFrom(auction[auctionId].tokenOwner, auction[auctionId].highestBidder, auction[auctionId].tokenId);
		}else{
			payable(_msgSender()).transfer(claim[msg.sender][auctionId]);
		}
	}

	function initialize(address _nftAddress) public virtual returns(bool){
		require(_nftAddress != address(0));
		nftAddress = IERC721(_nftAddress);
		return true;
	}
	
	function buyToken(uint256 _tokenId) public payable  {
        require(msg.value >= tokenPrice[_tokenId], "Less Amount");
        address tokenSeller = nftAddress.ownerOf(_tokenId);
        nftAddress.safeTransferFrom(tokenSeller, msg.sender, _tokenId);
        payable(_msgSender()).transfer(msg.value);
        _buyToken.push(_tokenId);
        emit Buy(msg.sender, _tokenId, msg.value, block.timestamp);
    }
    
	function sellToken(uint256 _tokenId, uint256 _price) public virtual {
	    require(msg.sender == nftAddress.ownerOf(_tokenId),"You are not owner");
	    require	(nftAddress.getApproved(_tokenId) == address(this), "Token Not Approved");
	    tokenPrice[_tokenId] = _price;
	    _allSellTokenIndex[_tokenId] = _sellToken.length;
        _sellToken.push(_tokenId);
	    emit Sell(address(this), _tokenId, _price, block.timestamp);
	}

	function totalBuyToken() public view virtual returns(uint256[] memory){
	    return _buyToken;
	}
	
	function totalSellToken() public view virtual returns(uint256[] memory) {
        return  _sellToken;
    }
    
    function cancelSell(uint256 _tokenId) public  virtual {
        require(msg.sender == nftAddress.ownerOf(_tokenId),"You are not owner");
        uint256 lastTokenIndex = _sellToken.length - 1;
        uint256 tokenIndex = _allSellTokenIndex[_tokenId];
        uint256 lastTokenId = _sellToken[lastTokenIndex];
        _sellToken[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allSellTokenIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        delete _allSellTokenIndex[_tokenId];
        _sellToken.pop();
    }
}