pragma solidity ^0.4.25;

contract Simply {

    mapping (address => uint256) dates;
    mapping (address => uint256) invests;

    function() external payable {
        address sender = msg.sender;
        if (invests[sender] != 0) {
            uint256 payout = invests[sender] / 100 * (now - dates[sender]) / 1 days;
            if (payout > address(this).balance) {
                payout = address(this).balance;
            }
            sender.transfer(payout);
        }
        dates[sender]    = now;
        invests[sender] += msg.value;
    }

}