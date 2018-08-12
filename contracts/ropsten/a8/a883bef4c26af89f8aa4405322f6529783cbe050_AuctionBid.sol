pragma solidity ^0.4.2;

contract AuctionBid {
    address admin;

    address public highestBidder;
    uint public highestPrice;
    bool ended;
    bool started;
    address public owner;
    uint public nextStep;
    mapping(address => uint) withdrawMoney;
    
    event HighestBidIncrease(address player, uint value);
    event AuctionEnded(address winner, uint value);
    
    constructor() public {
        admin = 0xd66faa1da31df7939597fe07ab6e9e8a57f096e8;
    }
    function startBidding(uint _startPrice) public {
        require(started == false, "The auction has started");
        require(ended == false, "The auction is closing.");
        owner = msg.sender;
        started = true;
        highestPrice = _startPrice;
        nextStep = highestPrice + (highestPrice*50)/100;
    }
    
    function bid() public payable {
        require(ended == false, "Auction ended");
        require(started == true, "The auction is closing.");
        require(msg.sender.balance > 0, "You have no money, let buy some");
        // nextStep = highestPrice + (highestPrice*50)/100;
        require(msg.value == nextStep, "Can&#39;t bid under the next price");

        if(highestBidder != 0x0000000000000000000000000000000000000000) {
            withdrawMoney[highestBidder] += highestPrice;
        }
        highestBidder = msg.sender;
        highestPrice = msg.value;
        emit HighestBidIncrease(msg.sender, msg.value);
        nextStep = highestPrice + (highestPrice*50)/100;
    }

    function auctionEnd() public {
        // require(msg.sender == admin, "Only the admin can do this");
        require(ended == false, "Auction not yet ended");
        ended = true;
        started = false;
        emit AuctionEnded (highestBidder, highestPrice);
        uint fees = (highestPrice * 10)/100;
        highestPrice -= fees;
       
        admin.transfer(fees);
        owner.transfer(highestPrice);
    }
    function withdraw() public  {
        require(msg.sender != highestBidder, "Can only withdraw money when auction ended");
        
        uint amount = withdrawMoney[msg.sender];
        if(amount > 0 ) {
            withdrawMoney[msg.sender] = 0;
            msg.sender.transfer(amount);
        }
    }
}