/**
 *Submitted for verification at Etherscan.io on 2021-12-05
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

struct Token {
    uint256 id;
    string name;
    string data;
    address owner;
	address creator;
    uint256 highestBid;
    address highestBidder;
    uint auctionEndTime;
}

contract Gallery {
    uint256 tokenCounter;
    Token[] tokens;
    mapping(address => uint256) accounts;

    constructor() {
        tokenCounter = 0;
    }

    event Transfer(address from, address to, uint256 value);
    event AuctionStart(uint256 id, uint256 auctionEndTime);

    function createToken(string memory _name, string memory _data) public returns (uint256) {
        Token memory token = Token({
			id: tokenCounter,
			name: _name,
			data: _data,
			owner: msg.sender,
			creator: msg.sender,
            highestBid: 0,
            highestBidder: address(0),
            auctionEndTime: 0
		});
        tokens.push(token);
        return tokenCounter++;
    }

    function startAuction(uint256 _tokenId, uint duration) public {
        Token memory token = tokens[_tokenId];
        require(msg.sender == token.owner, "msg.sender must be owner");
        if (token.highestBid > 0) {
            // then the auction is being restarted ignoring previous winner
            // need to make sure the previous highestBidder gets money back
            accounts[token.highestBidder] += token.highestBid;
        }
        token.auctionEndTime = block.timestamp + duration;
        tokens[_tokenId] = token;
        emit AuctionStart(_tokenId, token.auctionEndTime);
    }

    function bid(uint256 _tokenId) public payable {
        Token memory token = tokens[_tokenId];
        require(msg.sender != token.owner, "owner cannot bid");
        require(block.timestamp < token.auctionEndTime, "auction has ended");
        require(token.highestBidder != msg.sender, "msg.sender has already bid");
        require(token.highestBid < msg.value, "msg.value must be higher than highest bid");
        if (token.highestBid > 0) {
            accounts[token.highestBidder] += token.highestBid;
        }
        token.highestBid = msg.value;
        token.highestBidder = msg.sender;
        tokens[_tokenId] = token;
    }

	function endAuction(uint256 _tokenId) public {
		Token memory token = tokens[_tokenId];
		require(msg.sender == token.owner || msg.sender == token.highestBidder, "msg.sender must be owner or highest bidder");
		require(token.auctionEndTime < block.timestamp, "auction cannot be ended early");
		require(token.highestBid != 0, "auction has no highest bid");

		// calculate 5% royalty for creator. rest goes to owner
		uint256 royalty = token.highestBid * 5 / 100;
		accounts[token.creator] += royalty;
		accounts[token.owner] += token.highestBid - royalty;

		// give token to highest bidder
        emit Transfer(token.owner, token.highestBidder, token.highestBid);
		token.owner = token.highestBidder;
		token.highestBid = 0;
		token.highestBidder = address(0);
		token.auctionEndTime = 0;
        tokens[_tokenId] = token;
	}
		

    function withdraw() public {
        uint256 amount = accounts[msg.sender];
        require(amount > 0, "msg.sender has no amount to withdraw");
        payable(msg.sender).transfer(amount);
        accounts[msg.sender] = 0;
    }

    function balanceOf(address owner) view public returns (uint256) {
        uint256 balance = 0;
        for (uint256 i = 0; i < tokenCounter; i++) {
            if (tokens[i].owner == owner) {
                balance++;
            }
        }
        return balance;
    }

    function ownerOf(uint256 tokenId) view public returns (address) {
        return tokens[tokenId].owner;
    }
}