// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;

import "./ERC721.sol";
import "./Counters.sol";

contract NFT_Auction is ERC721{
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    address public admin;

    mapping(address => uint256) private refund_amount;
    mapping(uint256 => address) private original_creator;

    address private _auction_owner;
    uint256 private _auction_for;
    uint256 private _auction_end_time;
    uint256 private _highest_bid;
    address private _highest_bidder;
    uint256 private _minimum_amount;

    uint256 public payout_period ;

    constructor() ERC721("NFT_Sale", "SNFT") {
        admin = msg.sender;
        payout_period = 120;
    }

    // create NFT 
    function create_nft(address owner) public returns (uint256)
    {
        require(msg.sender == admin,"Admin Only");

        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _mint(owner, newItemId);
        original_creator[newItemId] = owner;
        return newItemId;
    }

    // start auction for particular token
    function start_auction(uint256 auction_for_token,uint256 duration,uint256 minimum_amount) public
    {
        require(block.timestamp > _auction_end_time+payout_period,"Auction already running.");
        require(msg.sender == ownerOf(auction_for_token),"Token owned by someone else.");

        _auction_owner = msg.sender;
        _auction_for = auction_for_token;
        _auction_end_time = block.timestamp + duration ;
        _minimum_amount = minimum_amount;
        _highest_bid = 0;
        _highest_bidder = address(0);
    }

    // place bid 
    function place_bid() public payable
    {
        require(block.timestamp < _auction_end_time,"Auction ended");
        require(msg.value >= _minimum_amount && msg.value > _highest_bid, "Amount less than highest bid") ;
        require(msg.sender != _auction_owner,"Auction owner cannot bid");

        // add refund amount
        if(_highest_bid != 0)
        {
            refund_amount[_highest_bidder] += _highest_bid;
        }

        // set new highest 
        _highest_bid = msg.value;
        _highest_bidder = msg.sender;
    }

    // withdraw amount after auction
    function refund() public
    {
        require(block.timestamp > _auction_end_time,"Refund only after auction ends");
        require(refund_amount[msg.sender] > 0, "Nothing to refund");
        
        if(refund_amount[msg.sender] !=0 )
        {
            payable(msg.sender).transfer(refund_amount[msg.sender]);
            refund_amount[msg.sender] = 0;
        }
    }

    function payout() public
    {
        require(msg.sender == _auction_owner,"Token owned by someone else.");
        require(block.timestamp > _auction_end_time, "Auction running");
        // within payout period
        if(block.timestamp <= _auction_end_time+payout_period)
        {
            // generate royalty of 1%
            uint256 royalty = _highest_bid/100;
            _highest_bid -= royalty;

            // pay owner, artist and transfer ownership
            payable(_auction_owner).transfer(_highest_bid);
            safeTransferFrom(_auction_owner, _highest_bidder, _auction_for);
            payable(original_creator[_auction_for]).transfer(royalty);
        }
        else
        {
            // revert auction
            payable(_highest_bidder).transfer(_highest_bid);
        }
    }

    function minimum_bid_amount() public view returns(uint256) {
        return _minimum_amount;
    }

    function auction_end_time() public view returns(uint256) {
        return _auction_end_time;
    }

    function highest_bid_amount() public view returns(uint256) {
        return _highest_bid;
    }
    function highest_bidder() public view returns(address) {
        return _highest_bidder;
    }
    function auction_owner() public view returns(address) {
        return _auction_owner;
    }
    function auction_token() public view returns(uint256) {
        return _auction_for;
    }
}