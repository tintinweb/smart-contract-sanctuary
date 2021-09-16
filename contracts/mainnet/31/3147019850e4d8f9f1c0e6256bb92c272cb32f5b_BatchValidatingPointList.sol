/**
 *Submitted for verification at Etherscan.io on 2021-09-16
*/

pragma solidity ^0.8.0;

interface BatchAuctionLike {
    struct MarketStatus {
        uint128 commitmentsTotal;
        uint128 minimumCommitmentAmount;
        bool finalized;
        bool usePointList;
    }

    function commitments(address) external view returns (uint);
    function marketStatus() external view returns (MarketStatus memory);
}


contract BatchValidatingPointList {
    function hasPoints(address who, uint newCommitment) public view returns (bool) {
        BatchAuctionLike auction = BatchAuctionLike(msg.sender);
        BatchAuctionLike.MarketStatus memory status = auction.marketStatus();

        uint expectedEth = status.commitmentsTotal - auction.commitments(who) + newCommitment;
        require(address(auction).balance >= expectedEth, "BatchValidatingPointList/invalid-eth");
        require(BatchValidatingPointList(0x5982E018d91f919819e1E1Ab9d1648144e637E49).hasPoints(who, newCommitment), "BatchValidatingPointList/upstream");

        return true;
    }
}