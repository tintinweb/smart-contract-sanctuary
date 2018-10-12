pragma solidity ^0.4.25;

contract Auction {
    
    address owner;
    
    struct Bid {
      address bidder;
      uint value;
    }
    
    struct AuctionStruct {
        string name;
        address lotOwner;
        uint expiryBlockHeight;
        Bid highestBid;
        Bid nextHighestBid;
    }
    
    mapping(bytes32 => AuctionStruct) public auctions;
    
    constructor() public {
        owner = msg.sender;
    }
    
    function createNewAuction(string _name, uint _expiryBlockHeight) public {
        auctions[keccak256(bytes(_name))] = AuctionStruct({name: _name, lotOwner: msg.sender, expiryBlockHeight: _expiryBlockHeight, highestBid: Bid({bidder: 0x0, value: 0}), nextHighestBid: Bid({bidder: 0x0, value: 0})});
    }
    
    function submitBid(string _name) public payable {
        require(auctions[keccak256(bytes(_name))].expiryBlockHeight > block.number);
        if (msg.value > auctions[keccak256(bytes(_name))].highestBid.value) {
            auctions[keccak256(bytes(_name))].nextHighestBid = auctions[keccak256(bytes(_name))].highestBid;
            auctions[keccak256(bytes(_name))].highestBid = Bid({bidder: msg.sender, value: msg.value});
            auctions[keccak256(bytes(_name))].nextHighestBid.bidder.transfer(auctions[keccak256(bytes(_name))].nextHighestBid.value);
            
            // Extend auction if a new highest bid is received under ~8 minutes before auction closes.
            // This is called a "soft close" auction. It disincentivizes bidders from only bidding at the last second.
            
            if ((auctions[keccak256(bytes(_name))].expiryBlockHeight - block.number) < 32) {
                auctions[keccak256(bytes(_name))].expiryBlockHeight += (32 - (auctions[keccak256(bytes(_name))].expiryBlockHeight - block.number));
            }
        } else {
            msg.sender.transfer(msg.value);
        }
    }
    
    function twoHightestBidsDifference(string _name) public view returns(uint) {
        if (auctions[keccak256(bytes(_name))].highestBid.value != 0) {
            return (auctions[keccak256(bytes(_name))].highestBid.value - auctions[keccak256(bytes(_name))].nextHighestBid.value);
        }
        return 0;
    }
    
    function executePayment(string _name) public {
        require(auctions[keccak256(bytes(_name))].expiryBlockHeight < block.number);
        auctions[keccak256(bytes(_name))].lotOwner.transfer(auctions[keccak256(bytes(_name))].highestBid.value);
        
        // Destroy auction
        auctions[keccak256(bytes(_name))].highestBid = Bid({bidder: 0x0, value: 0});
    }
    
    function winningBidder(string _name) public view returns (address) {
        return auctions[keccak256(bytes(_name))].highestBid.bidder;
    }
    
}