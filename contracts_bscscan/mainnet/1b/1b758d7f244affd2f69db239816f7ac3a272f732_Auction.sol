/**
 *Submitted for verification at BscScan.com on 2022-01-05
*/

pragma solidity 0.8.7;

contract Auction{
    
    event Start();
    address payable public seller;
    bool public started;
    bool public ended;
    uint public endAt;


    uint public highestBid;
    address public highestBidder;

    mapping(address => uint) public bids;

    constructor(){
        seller = payable(msg.sender);

    }

    function start()  external {
        require(!started, "Already started");
        require(msg.sender == seller, "You didnt start ");
        started = true;
        endAt = block.timestamp + 7 days;
        emit Start();
    }

}