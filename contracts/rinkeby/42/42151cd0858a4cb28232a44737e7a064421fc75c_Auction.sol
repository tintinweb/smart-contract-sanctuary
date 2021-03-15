/**
 *Submitted for verification at Etherscan.io on 2021-03-14
*/

pragma solidity ^ 0.4 .21;
contract Auction {

    struct Detail {
        string auctionId;
        string winnerBidId;
    }
    Detail public detail;

    function recordData(string auctionId, string winnerBidId) public {
        detail.auctionId = auctionId;
        detail.winnerBidId = winnerBidId;
    }

}