pragma solidity ^0.4.15;

contract TimeBroker 
{
    address owner;
    
    function TimeBroker()
    {
        owner = msg.sender;    
    }
    
    modifier isOwner()
    {
        assert(msg.sender == owner);
        _;
    }

    struct Seller
    {
        string FirstName;
        string SecondName;
        string MiddleName;
        string City;
        //uint256 rating;
    }
    
    mapping(address => Seller) public sellers;

    Auction[] auctions;
    
    struct Auction
    {
        address seller;
        uint256 bidsAcceptedBefore;
        uint256 datetime;
        uint64 duration;
        uint256 currentPrice;
        address winner;
        bool canceled;
    }
    mapping (uint256 => bool) auctionWithdrawDone;
    
    

    event RegisterSeller(address source, string FirstName, string SecondName, string MiddleName, string City);
    event NewAuction(address seller, uint256 index, uint256 bidsAcceptedBefore, uint256 datetime, uint64 duration, uint256 minPrice);
    event CancelAuction(address seller, uint256 index, uint256 bidsAcceptedBefore, uint256 datetime, uint64 duration, uint256 currentPrice, address winner);
    event AuctionFinished(address seller, uint256 index, uint256 bidsAcceptedBefore, uint256 datetime, uint64 duration, uint256 currentPrice, address winner);
    event Bid(address seller, uint256 index, address buyer, uint256 newPrice);
    event Withdraw(address seller, uint256 index, uint256 payToSeller);
    
    function registerAsSeller(address source, string FirstName, string SecondName, string MiddleName, string City) isOwner
    {
        sellers[source] = Seller(FirstName, SecondName, MiddleName, City);
        RegisterSeller(source, FirstName, SecondName, MiddleName, City);
    }

    function createAuction(uint256 bidsAcceptedBefore, uint256 datetime, uint64 duration, uint256 minPrice)
    {
        assert(bytes(sellers[msg.sender].FirstName).length > 0);
        assert(datetime > bidsAcceptedBefore);
        assert(datetime > now);
        assert(duration > 0);
        auctions.push(Auction(msg.sender, bidsAcceptedBefore, datetime, duration, minPrice, 0x0, false));
        NewAuction(msg.sender, auctions.length - 1, bidsAcceptedBefore, datetime, duration, minPrice);
    }

    function withdraw(uint256 index)
    {
        Auction storage auc = auctions[index];
        assert(auc.seller == msg.sender); // seller call function
        assert(now > auc.datetime + auc.duration); // meeting ended
        assert(auctionWithdrawDone[index] == false);
        auctionWithdrawDone[index] = true;
        uint256 payToSeller = auc.currentPrice * 95 / 100;
        assert(auc.currentPrice > payToSeller);
        auc.seller.transfer(payToSeller);               // 95% to seller
        owner.transfer(auc.currentPrice - payToSeller); // 5% to owner
        Withdraw(auc.seller, index, payToSeller);
    }


    function placeBid(uint256 index) payable
    {
        Auction storage auc = auctions[index];
        assert(auc.seller != msg.sender);
        assert(now < auc.bidsAcceptedBefore);
        assert(auc.canceled == false);
        assert(msg.value > auc.currentPrice);
        if (auc.winner != 0)
        {
            auc.winner.transfer(auc.currentPrice);
        }
        auc.currentPrice = msg.value;
        auc.winner = msg.sender;
        Bid(auc.seller, index, msg.sender, msg.value);
    }

    function kill() isOwner {
        selfdestruct(msg.sender);
    }


}