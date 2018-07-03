pragma solidity ^0.4.22;

contract SimpleAuction
{
    address public admin;
    address public highestBidder;
    address public previousBidder;

    bool isAuctionRunning;

    uint public highestBid;
    uint public previousBid;

    mapping(address => uint) pendingReturns;


    constructor(address _admin) public
    {
        admin = _admin;
        isAuctionRunning = true;
    }

    function bid() public payable
    {
        if(isAuctionRunning)
        {
            if(msg.value > highestBid)
            {
                if (highestBid != 0)
                {
                    pendingReturns[highestBidder] += highestBid;
                }
                previousBidder = highestBidder;
                previousBid = highestBid;
                
                highestBidder = msg.sender;
                highestBid = msg.value;
            }
        }
    }

    function withdraw() public returns (bool)
    {
        if(msg.sender == previousBidder)
        {
            previousBidder.transfer(previousBid);
            return true;
        }
    }

    function auctionEnd() public
    {
        if(isAuctionRunning)
        {
            isAuctionRunning = false;            
        }
        admin.transfer(highestBid);
    }
}