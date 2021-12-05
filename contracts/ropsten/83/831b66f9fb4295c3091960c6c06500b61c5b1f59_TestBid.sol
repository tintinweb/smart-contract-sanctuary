/**
 *Submitted for verification at Etherscan.io on 2021-12-05
*/

pragma solidity ^0.8.0;

contract TestBid {
    uint256 bid;
    address bidder;

    function auction() public view returns (uint256, address) {
        return (bid, bidder);
    }

    function makeBid() external payable {
        bid = msg.value;
        bidder = msg.sender;
    }
}