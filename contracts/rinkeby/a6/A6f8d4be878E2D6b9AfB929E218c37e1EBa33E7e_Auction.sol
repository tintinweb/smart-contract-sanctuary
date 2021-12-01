// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Auction {
    //public state variables
    address public owner; //contract and auction owner
    address public max_bidder; //address that placed the highest bid
    uint public max_bid_value; //current highest bid value
    uint public endtime; //bids can no longer be placed after this time
    mapping (address => uint) public bids; //maps bidders to bid values

    constructor(uint duration_minutes, uint starting_bid)  {
        require(duration_minutes <= 60);
        //set auction end time
        endtime = block.timestamp + duration_minutes * 60 seconds;
        //set contract and auction owner
        owner = msg.sender;
        //set starting bid value
        max_bid_value = starting_bid;
    }

    function place_bid() public payable {
        // Check if input is larger than max_bid_value
        require((bids[msg.sender] + msg.value) > max_bid_value);
        // Check that the auction is still open
        require(block.timestamp < endtime);
        require(msg.sender != owner);

        bids[msg.sender] += msg.value;
        max_bidder = msg.sender;
        max_bid_value = msg.value;

        // Update endtime if the bid is placed shortly before endtime
        if(block.timestamp > (endtime - 5 minutes)) {
            endtime = endtime + 5 minutes;
        }
    }

    function withdraw() public {
        require(msg.sender != max_bidder);
        require(msg.sender != owner);
        require(block.timestamp >= endtime);
        uint amount = bids[msg.sender];
        //check balance
        require(address(this).balance >= max_bid_value + amount);
        bids[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }

    function owner_withdraw() public {
        require(block.timestamp >= endtime); //withdraw after auction closed
        require(max_bid_value > 0); //prevent double withdraws
        uint amount = max_bid_value;
        max_bid_value = 0;
        payable(owner).transfer(amount);
    }

    function get_winner() public view returns (address) {
        require(block.timestamp >= endtime);
        return max_bidder;
    }

}