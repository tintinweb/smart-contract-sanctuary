/**
 *Submitted for verification at Etherscan.io on 2021-12-13
*/

pragma solidity ^0.8.6;

// Inputs: Auction item, auction duration, starting price, user bidding price
// Logic:
// user will bid, amount is sent to the contract only if the bid is current highest. The bid amount will be stored
// once the duration is over, winner of the auction gets the item, extra amount will be refunded to the users who lost
contract Auction {
    uint item = 5 ether;
    uint latestBid = 0.1 ether;
    bool auctionState = false;
    address owner;
    mapping(address => uint) public bidByAddress;
    mapping(uint => address) public amountByAddress;
    address[] biddersAddresses;

    constructor() {
        owner = msg.sender;
    }
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can run the function");
        _;
    }
    function startAuction() public onlyOwner {
        auctionState = true;
    }
    function endAuction() public onlyOwner {
        auctionState = false;
        determineWinnerAndRefund();
    }
    function bidAmount() external payable {
        require(msg.value > latestBid, "Please bid higher");
        require(auctionState, "auction not active yet");
        bidByAddress[msg.sender] = msg.value;
        amountByAddress[msg.value] = msg.sender;
        latestBid = msg.value;
        biddersAddresses.push(msg.sender);
    }        
    // TODO: Refund users who lost the auction
    function determineWinnerAndRefund() private onlyOwner {
        address payable winnerAddress = payable(amountByAddress[latestBid]);
        for(uint i = 0; i < biddersAddresses.length; i++) {
            if(winnerAddress == biddersAddresses[i]) {
                payable(biddersAddresses[i]).transfer(item + bidByAddress[biddersAddresses[i]]);
            } else {
                payable(biddersAddresses[i]).transfer(bidByAddress[biddersAddresses[i]]);
            }
        }
    }
    function getBiddersLength() public view returns(uint) {
        return biddersAddresses.length;
    }
    function setUpPrizeEth() public onlyOwner payable {
        return;
    } 
    function balance() public view returns(uint) {
        return address(this).balance;
    }
}