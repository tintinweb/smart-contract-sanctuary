/**
 *Submitted for verification at Etherscan.io on 2021-05-17
*/

pragma solidity ^0.5.0;

contract Auction {
    address payable public manager;
    address payable public seller;
    uint256 public latestBid;
    address payable public latestBidder;

    constructor() public {
        manager = msg.sender;
    }

    function auction(uint256 bid) public {
        latestBid = bid * 1 ether; //1000000000000000000;
        seller = msg.sender;
    }

    function bid() public payable {
        require(msg.value > latestBid);
        if (latestBidder != address(0)) {
            latestBidder.transfer(latestBid);
        }
        latestBidder = msg.sender;
        latestBid = msg.value;
    }

    function finishAuctionNew() public restricted {
        seller.transfer(address(this).balance);
    }

    modifier restricted() {
        require(msg.sender == manager);
        _;
    }

    function kill() public restricted {
        selfdestruct(manager);
    }
}