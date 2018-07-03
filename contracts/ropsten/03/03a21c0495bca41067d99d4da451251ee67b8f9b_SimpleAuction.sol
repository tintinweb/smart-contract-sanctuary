pragma solidity ^0.4.11;
contract SimpleAuction {
    address public beneficiaryAddress;
    uint public auctionClose;
    address public topBidder;
    uint public topBid;
    mapping(address => uint) returnsPending;
    bool auctionComplete;
    event topBidIncreased(address bidder, uint bidAmount);
    event auctionResult(address winner, uint bidAmount);
    function SimpleAuction(
        uint _biddingTime,
        address _beneficiary
    ) public {
        beneficiaryAddress = _beneficiary;
        auctionClose = now + _biddingTime;
    }
    function bid() payable {
        require(now <= auctionClose);
        require(msg.value > topBid);
        if (topBidder != 0) {
            returnsPending[topBidder] += topBid;
        }
        topBidder = msg.sender;
        topBid = msg.value;
        topBidIncreased(msg.sender, msg.value);
    }
    function withdraw() returns (bool) {
        uint bidAmount = returnsPending[msg.sender];
        if (bidAmount > 0) {
            returnsPending[msg.sender] = 0;
            if (!msg.sender.send(bidAmount)) {
                returnsPending[msg.sender] = bidAmount;
                return false;
            }
        }
        return true;
    }
    function auctionClose() {
        require(now >= auctionClose); 
        require(!auctionComplete); 
        auctionComplete = true;
        auctionResult(topBidder, topBid);
        beneficiaryAddress.transfer(topBid);
    }
}