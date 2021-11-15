/**
 *Submitted for verification at BscScan.com on 2021-11-15
*/

pragma solidity ^0.5.1;

contract auctionContract {

    address payable public auctionManager;
    enum State {Open, Pending, Ended}
    State public auctionState;
    mapping(uint => Auction) public auctionDetails;
    mapping(uint => Bid) public bidDetails;
    uint[] public auctions;
    uint[] public bids;
    uint public totalAuctions = 0;
    uint public totalBids = 0;
    Bid public winner;
    
    
    struct Auction{
        uint _auctionID;
        string _item;
        address payable _auctionManager;
        uint _minBid;
        State _auctionState;
    }
    
    struct Bid {
        uint _bidID;
        uint _auctionID;
        address payable _bidderAddress;
        uint _bid;
    }
    
    constructor () public {
        auctionManager = msg.sender;
    }
    
    function createAuction( string memory _item, uint _minBid ) public returns (uint) {
        require(msg.sender == auctionManager);
        totalAuctions++;
        // Here totalAuctions is taken as the auction ID. The first auction will have an ID of 1, second, an ID of 2 and so on. 
        auctionDetails[totalAuctions] = Auction(totalAuctions, _item, auctionManager, _minBid, State.Open);
        auctions.push(totalAuctions);
        return totalAuctions;
    }
    
    function bid(uint _auctionID, uint _bid) public returns (uint) {
        require(
            auctionDetails[_auctionID]._auctionState == State.Open &&
            msg.sender.balance >= _bid && 
            auctionDetails[_auctionID]._minBid <= _bid
            );
        totalBids++;
        // Here totalBids is taken as the bid ID. The first bid will have an ID of 1, second, an ID of 2 and so on. 
        bidDetails[totalBids] = Bid(totalBids, _auctionID, msg.sender, _bid);
        //Bids is a collection of all the bid IDs. 
        bids.push(totalBids);
        return totalBids;
    }
    
    function setWinner(uint _bidID, uint _auctionID) public{
        require(msg.sender == auctionManager);
        winner._bidID = bidDetails[_bidID]._bidID;
        winner._auctionID = bidDetails[_bidID]._auctionID;
        winner._bidderAddress = bidDetails[_bidID]._bidderAddress;
        winner._bid = bidDetails[_bidID]._bid;
        auctionDetails[_auctionID]._auctionState = State.Pending;
    }


    function pay(uint _auctionID, uint _bid) public payable{
        require(
            auctionDetails[_auctionID]._auctionState == State.Pending &&
            msg.sender.balance >= _bid &&
            winner._bidderAddress == msg.sender &&
            winner._bid == _bid
        ); 
        auctionManager.transfer(_bid);
    }
    
    function closeBid(uint _auctionID) public {
        require(msg.sender == auctionManager);
        auctionDetails[_auctionID]._auctionState = State.Ended;
    }
    
    
    
    
}