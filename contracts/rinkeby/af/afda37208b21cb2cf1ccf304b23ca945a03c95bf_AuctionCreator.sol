/**
 *Submitted for verification at Etherscan.io on 2021-10-07
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 <0.9.0;

contract AuctionCreator {
    Auction[] public auctions;
    
    function createAuction() public{
        Auction newAAdress = new Auction(msg.sender);
        auctions.push(newAAdress);
    }
}

contract Auction {
    address payable public owner;
    uint public startBlock;
    uint public endBlock;
    
    string public ipfsHash;
    
    enum State {Started, Running, Ended, Canceled}
    State public auctionState;
    
    uint public highestBindingBid;
    address payable public highestBidder;
    
    mapping(address => uint) public bids;
    
    uint bidIncrement;
    
    constructor(address eoa){
        owner = payable(eoa);
        startBlock = block.number;
        auctionState = State.Running;
        // endBlock = startBlock + 40320;
        endBlock = startBlock + 3;
        ipfsHash = '';
        bidIncrement = 1000000000000000000;
    }
    
    modifier onlyOwner(){
        require(msg.sender == owner, 'You are not the owner!');
        _;
    }
    
    modifier notOwner(){
        require(msg.sender != owner);
        _;
    }
    
    modifier afterStart(){
        require(block.number >= startBlock);
        _;
    }
    
    modifier beforeEnd(){
        require(block.number <= endBlock);
        _;
    }
    
    function min(uint a, uint b) pure internal returns(uint){
        if(a<=b){
            return a;
        } else {
            return b;
        }
    }
    
    function placeBid() public payable notOwner afterStart beforeEnd{
        require(auctionState == State.Running, 'Auction is not running!');
        require(msg.value >= 1000000000000000000, 'Your bid is too low!');
        
        uint currentBid = bids[msg.sender] + msg.value;
        require(currentBid > highestBindingBid, 'Your bid is too low!');
        
        bids[msg.sender] = currentBid;
        
        if(currentBid <= bids[highestBidder]){
            highestBindingBid = min(currentBid + bidIncrement, bids[highestBidder]);
        } else {
            highestBindingBid = min(currentBid, bids[highestBidder] + bidIncrement);
            highestBidder = payable(msg.sender);
        }
    }
    
    function cancelAuction() public onlyOwner beforeEnd afterStart {
        require(auctionState == State.Running);
        auctionState = State.Canceled;
    }
    
    function finalizeAuction() public {
        require(auctionState == State.Canceled || block.number > endBlock, 'The auction ended!');
        require(msg.sender == owner || bids[msg.sender] > 0, 'You are not a bidder, nor the owner!');
        
        address payable recipient;
        uint value;
        
        if(auctionState == State.Canceled){
            recipient = payable(msg.sender);
            value = bids[msg.sender];
        } else {
            if(msg.sender == owner){
                recipient = owner;
                value = highestBindingBid;
            }else {
                if(msg.sender == highestBidder){
                    recipient = highestBidder;
                    value = bids[highestBidder] - highestBindingBid;
                }else {
                    recipient = payable(msg.sender);
                    value = bids[msg.sender];
                }
            }
        }
        bids[recipient] = 0;
        
        recipient.transfer(value);
        auctionState = State.Ended;
    }
}