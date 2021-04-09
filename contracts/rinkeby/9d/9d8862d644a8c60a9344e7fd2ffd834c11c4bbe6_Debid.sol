/**
 *Submitted for verification at Etherscan.io on 2021-04-08
*/

// SPDX-License-Identifier: RANDOM_TEXT
pragma solidity ^0.8.0;

/** TO DO  */
//Listing all bids (mapping address -> bid) 
//Transfer NFT to auction contract from owner
//Transfer NFT to highest bidder from contract

contract Debid {
    
    struct Bid{
        address payable bidder;
        uint amount;
        uint time;
        //uint auctionId;
        //uint number;
    }
    
    struct Auction{
        address payable owner;
        string title;
        string description;
        uint auctionTime;
        uint startPrice;
        bool isActive;
        //Bid highestBid;
    } 
    
    Auction[] internal auctions;
    
    mapping(address => uint[]) private auctionIdsOfUser;    // userAddress -> auctionIdList
    mapping(uint => Bid[]) bidsOfAuction;	                // auctionId -> BidList   (Last is always highest)
    mapping(address => uint) refunds;                       // userAddress -> refundAmount
    //mapping(address => Bid[]) bidsOfUser;                   // userAddress -> BidList
     
    event AuctionCreated(uint id, string title, uint startingPrice);
    //event AuctionStarted(uint id);
    event HighestBidIncreased(address bidder, uint amount);
    event AuctionClosedWithNoBids(uint id);
    event AuctionClosed(uint id, address bidder, uint amount);
     
    constructor (address payable _owner, string memory _title, string memory _description, uint _startPrice, uint _auctionTime) {
        require(msg.sender == _owner);
        require(block.timestamp <= _auctionTime, "Auction has ended!");
        
        Auction memory a;
        a.owner = _owner;
        a.title = _title;
        a.description = _description;
        a.startPrice = _startPrice;
        a.auctionTime = block.timestamp + _auctionTime;   
        a.isActive = true;                                  // StartAuction() can activate it.
        
        auctions.push(a);
        uint auctionId = auctions.length;
        auctionIdsOfUser[_owner].push(auctionId);
        
        emit AuctionCreated(auctionId, _title, _startPrice);
    }
   
    // function startAuction(uint _auctionId) public {
    //     Auction memory auction = auctions[_auctionId-1];
    //     auction.isActive = true;
    //     emit AuctionStarted(_auctionId);
    // }

    function getAuctionDetailsById(uint _auctionId) public view returns (
        address payable, string memory, string memory, uint, bool ,uint){
        Auction memory a =  auctions[_auctionId-1];
        return (a.owner, a.title, a.description, a.startPrice, a.isActive, a.auctionTime);
    }
    
    function getAuctionIdsByUser(address _user) public view returns (uint[] memory){
        return auctionIdsOfUser[_user];
    }
    
    function getAuctionCountByUser(address _user) public view returns (uint){
        return  auctionIdsOfUser[_user].length;
    }
    
    function bid(address payable _bidder, uint _bidAmount) public payable returns (bool){ 
        // aucitonId can be passed as parameter.
        // uint amount = msg.value; address bidder = msg.sender; instead of parameters above.
        
        uint auctionId = auctions.length; 
        require(auctionId > 0, "No auction has been created yet!");
         
        Auction memory auction = auctions[auctionId-1];
        
        require(auction.isActive, "Auction must be started!");
        require(msg.sender != auction.owner, "Owner cannot place bids!");
        require(block.timestamp <= auction.auctionTime, "Auction has ended!");
        require(_bidAmount >= auction.startPrice && _bidAmount > 0, "Bid must be greater than or equal to the start price!");
       
        Bid[] memory bids = bidsOfAuction[auctionId];
        
        if (bids.length > 0){
            Bid memory lastHighestBid = bids[bids.length-1];
            require(_bidAmount > lastHighestBid.amount, "Bid must be greater than the previous bid!");
        }
        
        //uint bidNumber = bidsOfAuction[auctionId].length+1;     
      
        Bid memory currentBid;
        currentBid.bidder = _bidder;            // msg.sender
        currentBid.amount = _bidAmount;         // msg.value
        currentBid.time = block.timestamp;
        
        //currentBid.auctionId = auctionId;
        //currentBid.number = bidNumber;
        
        bidsOfAuction[auctionId].push(currentBid);                  // Add current highestBid to the auction.
        //bidsOfUser[_bidder].push(currentBid);                       // Add current highestBid to the user.
        
        //auction.highestBid = currentBid;
      
        if (_bidAmount != 0 &&  bids.length > 1) {                  // Last one is the current highest, if there is one more bid with it:
         	Bid memory previousBid = bids[bids.length-2];           // Refund the previous one.
         	refunds[previousBid.bidder] += previousBid.amount;
        }
        
        emit HighestBidIncreased(_bidder, _bidAmount);
        return true;
    }
    
    function getCurrentHighestBid(uint _auctionId) public view returns (address, uint, uint){
        // uint auctionId = auctions.length;
        require(_auctionId > 0, "No auction has been created yet!");
        
        Bid[] memory bids = bidsOfAuction[_auctionId];
        require(bids.length > 0, "No bid has been placed yet!");
        Bid memory highest = bids[bids.length-1];
        
        return (highest.bidder, highest.amount, highest.time);
    }
    
    function getBidCountOfAuction(uint _auctionId) public view returns (uint){
        require(_auctionId > 0, "No auction has been created yet!");
        return bidsOfAuction[_auctionId].length;
    }
    
    // function getBidCountOfUser(uint _auctionId, address _user) public view returns (uint){
    //     require(_auctionId > 0, "No auction has been created yet!");
    //     return bidsOfUser[_user].length;
    // }
    
    function withdraw(uint _auctionId) public returns (bool) {
        require(_auctionId > 0, "No auction has been created yet!");
        
        Bid[] memory bids = bidsOfAuction[_auctionId];
        require(bids.length > 0, "No bid has been placed yet!");
        Bid memory highest = bids[bids.length-1];
       
        uint amount = refunds[highest.bidder];
        if (amount > 0) {
            refunds[highest.bidder] = 0;
        }
        
        return true;
    }
    
    function closeAuction(uint _auctionId) public returns (bool){
        Auction memory auction = auctions[_auctionId];
        
        require(auction.isActive, "Auction must be started!");
        require(msg.sender == auction.owner, "Only owner!");
        require(block.timestamp >= auction.auctionTime, "Auction time has not been completed yet!");
        
        Bid[] memory bids = bidsOfAuction[_auctionId];
        if (bids.length < 0){                           // If no bid has been placed.
        
            emit AuctionClosedWithNoBids(_auctionId);
        }
        else {
            Bid memory highest = bids[bids.length-1];
            refunds[highest.bidder] += highest.amount;
            address payable reciever;
            uint value;
            
            if (msg.sender == auction.owner){               // Owner gets the money
               	reciever = auction.owner;
               	value = highest.amount;
         	} else if (msg.sender == highest.bidder){       // Bidder gets no money
               	reciever = highest.bidder;
               	value = 0;
         	} else {                                        // Others will be refunded
                // reciever = payable(msg.sender);
               	// value = 0; 
         	}
         	
         	// TO-DO: Clear Bids
         	reciever.transfer(value);
         
     	    emit AuctionClosed(_auctionId, highest.bidder, highest.amount);
        }
        
       	auction.isActive = false;
        return true;
    }

}