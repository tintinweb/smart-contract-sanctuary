/*
Lab 6: Auction Smart contract

The objective for this lab is to create a smart contract that can be reused to create auctions.

Yanesh
*/

pragma solidity ^0.4.25;

contract Auction {
    
    address owner;
    
    struct Bid {
      address bidder;
      uint value;
    }
    
    struct AuctionStruct {
        string name;
        uint expiryBlockHeight;
        Bid highestBid;
        Bid nextHighestBid;
    }
    
    mapping(bytes32 => AuctionStruct) public auctions;
    
    constructor() public {
        owner = msg.sender;
    }
    
    // This function should create a new AuctionStruct (assigning empty values where appropriate) 
    //and then insert the new Auction into the auctions mapping using the keccak256 hash of _name as the key value.
    function createNewBid(string _name, uint _expiryBlockHeight) public{

        Bid memory initialBid = Bid({bidder: 0x0, value: 0});
        AuctionStruct memory newAuction = AuctionStruct({name: _name, expiryBlockHeight: _expiryBlockHeight, highestBid: initialBid, nextHighestBid: initialBid});
        bytes memory nameBytes = bytes(_name);
        bytes32 key_value = keccak256(nameBytes);
        auctions[key_value] = newAuction;
    }

    // This function should allow addresses to submit bids. The function should check that the expiryBlockHeight has not passed. 
    // Then it should check that the msg.value is greater than the highestBid available and the existing bids should be replaced or removed as appropriate. 
    // If a bid is replaced, the funds should be returned the the bidder (such that only the bidder for the highestBid will have eth deposited in the contract).
    function submitBid(string _name) public payable {

        bytes memory nameBytes = bytes(_name);
        bytes32 key_value = keccak256(nameBytes);
        AuctionStruct memory retrievedAuction = auctions[key_value];
        
        require(block.number < retrievedAuction.expiryBlockHeight);
        require(msg.value > retrievedAuction.highestBid.value);
        
        Bid memory currentBid = Bid({bidder: msg.sender, value: msg.value});
        
        // refund the old highest bidder as they move to next highest bidder,
        // then add the new bid as highest bidder.
        retrievedAuction.highestBid.bidder.transfer(retrievedAuction.highestBid.value);
        retrievedAuction.nextHighestBid = retrievedAuction.highestBid;
        retrievedAuction.highestBid = currentBid;
        auctions[key_value] = retrievedAuction;     // update auction mapping (since retrievedAuction is in memory)
    }
    
    // This functions returns the difference between the highest bid and the next highest bid for the given auction.
    function twoHightestBidsDifference(string _name) public view returns(uint) {

        bytes memory nameBytes = bytes(_name);
        bytes32 key_value = keccak256(nameBytes);
        AuctionStruct memory retrievedAuction = auctions[key_value];
        
        return retrievedAuction.highestBid.value - retrievedAuction.nextHighestBid.value;
        
    }

    // This function will check if the expiryBlock for the given auction has passed. If it has, then the difference between 
    //the 2 highest bids will be returned the the winning bidder. The rest will be burned (transferred to 0x0)
    function executePayment(string _name) public {

        bytes memory nameBytes = bytes(_name);
        bytes32 key_value = keccak256(nameBytes);
        AuctionStruct memory retrievedAuction = auctions[key_value];
        
        require(block.number >= retrievedAuction.expiryBlockHeight);
        uint difference = retrievedAuction.highestBid.value - retrievedAuction.nextHighestBid.value;
        retrievedAuction.highestBid.bidder.transfer(difference);    // send difference to highest bidder
        address(0x0).transfer(address(this).balance);   // burn
    }

    // This function should return the winner&#39;s address for the given auction.
    function winningBidder(string _name) public view returns (address) {
        
        bytes memory nameBytes = bytes(_name);
        bytes32 key_value = keccak256(nameBytes);
        AuctionStruct memory retrievedAuction = auctions[key_value];
        
        return retrievedAuction.highestBid.bidder;
    }

}