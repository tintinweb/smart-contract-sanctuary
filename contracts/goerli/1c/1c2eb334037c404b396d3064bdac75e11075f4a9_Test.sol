/**
 *Submitted for verification at Etherscan.io on 2021-03-17
*/

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

interface IBaseAuction {
    function getBaseInformation() external view returns (
            address auctionToken,
            uint64 startTime,
            uint64 endTime,
            bool finalized
        );
}

contract Test {
        
    function sevenDays() public pure returns(uint256) {
        return 7 days;
    }
    
    function getMarkets(address _addr) public view returns (address) {
        address auctionToken;
        uint64 startTime;
        uint64 endTime;
        bool finalized;
        (auctionToken, startTime, endTime, finalized) = IBaseAuction(
            _addr
        ).getBaseInformation();
        
        return auctionToken;
    }
}