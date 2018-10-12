pragma solidity ^0.4.25;

contract auction {
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
    
    constructor() public{
        owner =msg.sender;
    }
    
    function createNewAuction(string _name, uint _expiryBlockHeight) public {
        auctions[keccak256(abi.encodePacked(_name))] = AuctionStruct(_name, _expiryBlockHeight, Bid(address(0), 0), Bid(address(0),0));
    }
    
     function submitBid(string _name) public payable {
        require(block.number < auctions[keccak256(abi.encodePacked(_name))].expiryBlockHeight);
        require(msg.value > auctions[keccak256(abi.encodePacked(_name))].highestBid.value);
        auctions[keccak256(abi.encodePacked(_name))].nextHighestBid.bidder.transfer(auctions[keccak256(abi.encodePacked(_name))].nextHighestBid.value);
        auctions[keccak256(abi.encodePacked(_name))].nextHighestBid = auctions[keccak256(abi.encodePacked(_name))].highestBid;
        Bid memory newHighestBid = Bid({bidder: msg.sender, value: msg.value});
        auctions[keccak256(abi.encodePacked(_name))].highestBid = newHighestBid;
    }
     
    function twoHightestBidsDifference(string _name) public view returns(uint) {
         return auctions[keccak256(abi.encodePacked(_name))].highestBid.value - auctions[keccak256(abi.encodePacked(_name))].nextHighestBid.value;
    }
     
    function executePayment(string _name) public {
        require(block.number > auctions[keccak256(abi.encodePacked(_name))].expiryBlockHeight);
        auctions[keccak256(abi.encodePacked(_name))].highestBid.bidder.transfer(twoHightestBidsDifference(_name));
        address(0x0).transfer(auctions[keccak256(abi.encodePacked(_name))].nextHighestBid.value);
    }
    
    function winningBidder(string _name) public view returns (address) {
        return auctions[keccak256(abi.encodePacked(_name))].highestBid.bidder;
    }
}