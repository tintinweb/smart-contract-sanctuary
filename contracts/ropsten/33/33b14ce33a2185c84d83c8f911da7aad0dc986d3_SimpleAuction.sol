/**
 *Submitted for verification at Etherscan.io on 2021-06-16
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

/// @title Implement the public auction
/// @author HUST Blockchain Research Group
///  Note: Blockchain course assignment code, Group ID 7
contract SimpleAuction {
    // Parameters of the current auction
    // Beneficiary of the auction
    address payable public beneficiary;
    // End time of the auction
    uint256 public endTime;
    // Highest bidder address
    address public highestBidder;
    // Highest bid
    uint256 public highestBid;
    // Return funds
    mapping(address => uint256) userBidAmount;
    // Whether the auction is over
    bool isOver;
    // Contract deployer
    address private owner;

    // Higher bids appear
    event HighestBidIncreased(address bidder, uint256 amount);
    // End of auction
    event IsOver(address winner, uint256 amount);
    
    /// @dev Initialize using constructor
    constructor() {
        owner = msg.sender;
    }
    
    /// @dev Generate an auction
    function generateTheAuction(uint256 _biddingTime, address payable _beneficiary) public {
        require(_beneficiary != address(0), "Invalid address.");
        beneficiary = _beneficiary;
        endTime = block.timestamp + _biddingTime;
    }
    /// @dev Auction bid
    function bid() public payable {
        require(block.timestamp <= endTime, "The auction is over.");
        require(msg.value > highestBid, "There already is a higher bid.");
        // Refund the previous highest price
        if (highestBid != 0) {
            userBidAmount[highestBidder] += highestBid;
        }
        highestBidder = msg.sender;
        highestBid = msg.value;
        // Trigger the highest price event
        emit HighestBidIncreased(msg.sender, msg.value);
    }

    /// Users get their bids back
    function withdraw() public returns (bool) {
        uint amount = userBidAmount[msg.sender];
        if (amount > 0) {
            // Prevent multiple calls
            userBidAmount[msg.sender] = 0;
            if (!payable(msg.sender).send(amount)) {
                // Reset state
                userBidAmount[msg.sender] = amount;
                return false;
            }
        }
        return true;
    }

    /// @dev End the auction
    function endTheAuction() public {
        require(block.timestamp >= endTime, "The auction is not over.");
        require(!isOver, "endTheAuction has already been called.");
        isOver = true;
        emit IsOver(highestBidder, highestBid);
        beneficiary.transfer(highestBid);
    }
    
    /// @dev Termination of contract
    function endTheContract() public {
        require(block.timestamp >= endTime, "The auction is not over.");
        require(msg.sender == owner, "Only the deployer can terminate the contract.");
        selfdestruct(payable(owner));
    }
}