// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";

contract VineAuction is ERC721 {

    address public beneficiary;
    uint public auctionEndTime;
    address public highestBidder;
    uint public highestBid;
    mapping(address => uint) pendingReturns;
    bool ended;
    event HighestBidIncreased(address bidder, uint amount);
    event AuctionEnded(address winner, uint amount);
    error AuctionAlreadyEnded();
    error BidNotHighEnough(uint highestBid);
    error AuctionNotYetEnded();
    error AuctionEndAlreadyCalled();
    
    constructor () ERC721 ("Vina Vepar", "VEPAR"){
        beneficiary = msg.sender;
        auctionEndTime = block.timestamp + 100;
    }

    function showAuctionTime() view public returns (uint256)
    {
        return auctionEndTime;
    }


     function bid() public payable {
        if (block.timestamp > auctionEndTime)
            revert AuctionAlreadyEnded();

        if (msg.value <= highestBid)
            revert BidNotHighEnough(highestBid);
        if (highestBid != 0) {
            pendingReturns[highestBidder] += highestBid;
        }
        highestBidder = msg.sender;
        highestBid = msg.value;
        emit HighestBidIncreased(msg.sender, msg.value);
    }

    function withdraw() public returns (bool) {
        uint amount = pendingReturns[msg.sender];
        if (amount > 0) {
            
            pendingReturns[msg.sender] = 0;
            if (!payable(msg.sender).send(amount)) {
            
            pendingReturns[msg.sender] = amount;
            return false;
            }
        }
        return true;
    }

    function auctionEnd() public {
        if (block.timestamp < auctionEndTime)
            revert AuctionNotYetEnded();
        if (ended)
            revert AuctionEndAlreadyCalled();
       
        ended = true;
        emit AuctionEnded(highestBidder, highestBid);
        _safeMint(highestBidder, 0);
        _setTokenURI(0, "https://ipfs.io/ipfs/QmZBcQa9MHJePMG4pyGpgvpSTKg1zZVw3dJQtdpAN7mrjc?filename=wine.json");
        payable(beneficiary).transfer(highestBid);
    }
    
}