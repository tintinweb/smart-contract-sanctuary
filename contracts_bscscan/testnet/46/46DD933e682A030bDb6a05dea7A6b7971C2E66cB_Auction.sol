/**
 *Submitted for verification at BscScan.com on 2021-07-24
*/

pragma solidity^0.6.0;

contract Auction{
    address payable public seller;
    address payable public auctioneer;
    
    address payable public buyer;
    
    uint public auctionAmount;
    
    uint auctionEndTime;
    
    bool isFinished;
    
    constructor(address payable _seller,uint _duration) public{
        seller = _seller;
        auctioneer = msg.sender;
        auctionEndTime = now + _duration;
        isFinished = false;
    }
    
    //jingpai
    function bid() public payable{
        require(!isFinished,"auction already end");
        require(msg.value>0,"please int value > 0");
        require(now < auctionEndTime);
        require(msg.value > auctionAmount);
        if(auctionAmount > 0 && address(0) !=buyer){
            buyer.transfer(auctionAmount);
        }
        buyer = msg.sender;
        auctionAmount = msg.value;
    }
    
    function auctionEnd() public payable{
        require(now >=auctionEndTime);
        require(!isFinished);
        isFinished = true;
        seller.transfer(auctionAmount);
    }
    
}