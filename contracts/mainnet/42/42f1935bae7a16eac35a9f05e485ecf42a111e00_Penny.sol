pragma solidity ^0.4.20;

contract Penny {

    //owner of contract
    address public owner;
    
    //last bidder and winner
    address public latestBidder;
    address public latestWinner;
    
    //time left of auction
    uint public endTime;
    uint public addTime;
    
    //event for auctions bid
    event Bid(address bidder, uint ending, uint adding, uint balance);

    //constructor
    function Penny() public {
        owner           = msg.sender;
        latestBidder    = msg.sender;
        latestWinner    = msg.sender;
        addTime         = (2 hours);
        endTime         = 0;
    }

    //bid on auction
    function bid() payable public{
        
        //bid must be precisely 0.005 ETH
        require(msg.value == 5000000000000000);

        //place first bid
        if(endTime == 0){
            endTime = (now + addTime);
        }
        
        //place a bid
        if(endTime != 0 && endTime > now){
            addTime -= (10 seconds);
            endTime = (now + addTime);
            latestBidder = msg.sender;
            Bid(latestBidder, endTime, addTime, this.balance);
        }
        
        //winner found, restart auction
        if(addTime == 0 || endTime <= now){
            latestWinner = latestBidder;
            
            //restart auction
            addTime = (2 hours);
            endTime = (now + addTime);
            latestBidder = msg.sender;
            Bid(latestBidder, endTime, addTime, ((this.balance/20)*17)+5000000000000000);
            
            //transfer winnings
            owner.transfer((this.balance/20)*1);
            latestWinner.transfer(((this.balance-5000000000000000)/10)*8);
        }
    }
    
    //allow for eth to be fed to the contract
    function() public payable {}
}