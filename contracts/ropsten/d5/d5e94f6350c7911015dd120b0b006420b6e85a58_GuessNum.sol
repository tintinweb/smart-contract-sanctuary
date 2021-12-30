/**
 *Submitted for verification at Etherscan.io on 2021-12-30
*/

pragma solidity ^0.4.22;

contract GuessNum {
    mapping(address => uint256) userBalance;
    uint256 PrizePool;

    constructor() public payable {
        PrizePool = msg.value;
    }

    function guess(uint256 num) external payable {
        uint256 luckyNum = uint256(
            keccak256(abi.encodePacked(block.timestamp, now))
        );
        PrizePool = PrizePool + msg.value;
        if (num > luckyNum && msg.value == 50 finney) {
            userBalance[msg.sender] = userBalance[msg.sender] + msg.value * 2;
        }
    }

    function getReward() external payable {
        if (
            userBalance[msg.sender] < PrizePool && userBalance[msg.sender] > 0
        ) {
            msg.sender.call.value(userBalance[msg.sender])();
            PrizePool = PrizePool - userBalance[msg.sender];
            userBalance[msg.sender] = 0;
        }
    }
}