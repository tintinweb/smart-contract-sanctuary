//Lab 6 - Auction Smart Contract
//The objective for this lab is to create a smart contract that can be reused to create auctions.


pragma solidity ^0.4.25;
//pragma experimental ABIEncoderV2;
contract Auction{
    
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
    
    mapping(bytes8 => AuctionStruct) public auctions;


    //should set the owner to be msg.sender
    constructor() public{
        owner = msg.sender;
    }
    
    
    //Mark&#39;s function to make code simpler&#39;
    function strToBytes(string _str) private pure returns (bytes8){
        return bytes8(keccak256(abi.encodePacked(_str)));
    }


    //This function should create a new AuctionStruct (assigning empty values where appropriate) and 
    //then insert the new Auction into the auctions mapping using the keccak256 hash of _name as the key value.
    function createNewAuction(string _name, uint _expiryBlockHeight) public {
        //require the name doesn&#39;t already exist <--> should change to expiryblockheight != null or something
        require(!(auctions[strToBytes(_name)].expiryBlockHeight > 0));
        //only callable by owner
        require(msg.sender==owner);
        //initialize values;
            auctions[strToBytes(_name)].name = _name;
            auctions[strToBytes(_name)].expiryBlockHeight = _expiryBlockHeight;//block.number + 500;
            auctions[strToBytes(_name)].highestBid.bidder = 0x0;
            auctions[strToBytes(_name)].highestBid.value = 0;
            auctions[strToBytes(_name)].nextHighestBid.bidder = 0x0;
            auctions[strToBytes(_name)].nextHighestBid.value = 0;
    }
    
    //This function should allow addresses to submit bids. The function should check that the 
    //expiryBlockHeight has not passed. Then it should check that the msg.value is greater than the 
    //highestBid or nextHighest bid. If it is greater than either bid, a new bid should be created 
    //that replaces the next highest bid. If a bid is replaced, the funds should be returned the the 
    //bidder (such that only the bidder for the highestBid will have eth deposited in the contract).
    function submitBid(string _name) public payable{
        //check if the auction doesn&#39;t exist
        require(auctions[strToBytes(_name)].expiryBlockHeight!=0);
        
       //check expiryBlockHeight has not passed
        require(block.number <= auctions[strToBytes(_name)].expiryBlockHeight);
        //a bid higher than nextHighestBid will also be higher than highestBid
        require(msg.value > auctions[strToBytes(_name)].nextHighestBid.value);
            //if msg.value > highestbid 
            if (msg.value > auctions[strToBytes(_name)].highestBid.value){
                //move data from highestBid to nexthighestBid and return funds to highestBidder
                auctions[strToBytes(_name)].nextHighestBid.bidder = auctions[strToBytes(_name)].highestBid.bidder;
                auctions[strToBytes(_name)].nextHighestBid.value = auctions[strToBytes(_name)].highestBid.value;
                auctions[strToBytes(_name)].highestBid.bidder.transfer(auctions[strToBytes(_name)].highestBid.value);
                
                //put msg.sender and msg.value into highestBid
                auctions[strToBytes(_name)].highestBid.bidder = msg.sender;
                auctions[strToBytes(_name)].highestBid.value = msg.value;
            }
            else{
                //put msg.sender and msg.value into nextHighestBid and reject the payment sent
                auctions[strToBytes(_name)].nextHighestBid.bidder = msg.sender; //CAN BE REMOVED TO SAVE ON GAS
                auctions[strToBytes(_name)].nextHighestBid.value = msg.value;
                msg.sender.transfer(msg.value);
            }
    }
    
    //This functions returns the difference between the highest bid and the next highest bid for the given auction.
    function twoHightestBidsDifference(string _name) public view returns(uint){
        return (auctions[strToBytes(_name)].highestBid.value - auctions[strToBytes(_name)].nextHighestBid.value);
    }
    
    //This function will check if the expiryBlock for the given auction has passed. If it has, then the 
    //difference between the 2 highest bids will be returned the the winning bidder. The rest will be 
    //burned (transferred to 0x0)
    function executePayment(string _name) public{
        require(auctions[strToBytes(_name)].expiryBlockHeight < block.number);
            winningBidder(_name).transfer(twoHightestBidsDifference(_name));
            //burn excess ether
            0x1111111111111111111111111111111111111111.transfer(auctions[strToBytes(_name)].nextHighestBid.value);
            //sets the highestbidder to a diagnostic value
            //auctions[strToBytes(_name)].nextHighestBid.bidder = 0x1111111111111111111111111111111111111111;
    }
    
    //This function should return the winner&#39;s address for the given auction.
    function winningBidder(string _name) public view returns (address){
        return (auctions[strToBytes(_name)].highestBid.bidder);
    }

    //extra debugging functions
    function currentBlockHeight() public view returns(uint){
        return (block.number);
    }
    
    function showAuction(string _name) public view returns(string,uint,address,uint,address,uint){
        return( auctions[strToBytes(_name)].name,
                auctions[strToBytes(_name)].expiryBlockHeight,
                auctions[strToBytes(_name)].highestBid.bidder,
                auctions[strToBytes(_name)].highestBid.value,
                auctions[strToBytes(_name)].nextHighestBid.bidder,
                auctions[strToBytes(_name)].nextHighestBid.value);
            
    }
}