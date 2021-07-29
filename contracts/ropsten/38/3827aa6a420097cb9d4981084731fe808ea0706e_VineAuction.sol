// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";

contract VineAuction is ERC721 {

    address public beneficiary;
    uint public auctionEndTime;
    address public highestBidder;
    uint public highestBid;
    uint creatorInsurance;
    uint bidderInsurance;
    uint startingBid = 0.01 ether;
    mapping(address => uint) pendingReturns;
    bool ended;
    bool itemClaimed;
    bool itemReceived;
    event HighestBidIncreased(address bidder, uint amount);
    event AuctionEnded(address winner, uint amount);
    error AuctionAlreadyEnded();
    error BidNotHighEnough(uint highestBid);
    error AuctionNotYetEnded();
    error AuctionEndAlreadyCalled();
    
    constructor () ERC721 ("Vina Vepar", "VEPAR"){
        beneficiary = msg.sender;
        auctionEndTime = block.timestamp + 240;
        highestBid = startingBid;
    }

   
    /* function sendViaCall(uint amount) public {
        // Call returns a boolean value indicating success or failure.
        // This is the current recommended method to use.
        (bool sent, bytes memory data) = payable(address(this)).call{value: amount}("");
        require(sent, "Failed to send Ether");
    }*/

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

    function claimPhysicalItem() public payable {
        require(msg.value >= startingBid);
        require(!itemClaimed, "Item already claimed");
        require(ended, "Auction is still ongoing");
        require(msg.sender==highestBidder, "Only Auction Winner can claim physical item");
        bidderInsurance = msg.value;
        //sendViaCall(inssurance);
        itemClaimed=true;
    }

    function physicalItemRecieved() public {
        require(!itemReceived, "Item already received");
        require(itemClaimed, "Item is not jet claimed");
        require(msg.sender==highestBidder, "Only Auction Winner can claim physical item");
        payable(highestBidder).transfer(bidderInsurance);
        payable(beneficiary).transfer(creatorInsurance);
        itemReceived=true;
    }

    function auctionEnd() public payable {
        require(msg.value >= startingBid);
        if (block.timestamp < auctionEndTime)
            revert AuctionNotYetEnded();
        if (ended)
            revert AuctionEndAlreadyCalled();
         
        creatorInsurance = msg.value;
        ended = true;
        emit AuctionEnded(highestBidder, highestBid);
        _safeMint(highestBidder, 0);
        _setTokenURI(0, "https://ipfs.io/ipfs/QmZBcQa9MHJePMG4pyGpgvpSTKg1zZVw3dJQtdpAN7mrjc?filename=wine.json");
        //sendViaCall(inssurance);
        payable(beneficiary).transfer(highestBid);
    }
    
}