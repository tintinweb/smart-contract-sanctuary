pragma solidity ^0.4.24;

/**
 *
 * Worldwide Socialist Fund
 *  - GAIN 3% PER 24 HOURS (every 5900 blocks)
 *  - NO FEES on your investment
 *  - NO FEES are collected by the contract creator
 *
 * How to use:
 *  1. Send any amount of Ether to contract address to make an investment
 *  2a. Claim your profit by sending 0 Ether transaction
 *  2b. Send more Ether to reinvest and claim your profit at the same time
 * 
 * The maximum withdrawal amount is 10% of the current amount in the fund
 *
 * Recommended Gas Limit: 100000
 * Recommended Gas Price: https://ethgasstation.info/
 *
 */

contract WSF {
    uint public raised;
    
    mapping (address => uint) public invested;
    mapping (address => uint) public investBlock;
    
    event FundTransfer(address backer, uint amount, bool isContribution);

    function () external payable {
        if (invested[msg.sender] != 0) {
            uint withdraw = invested[msg.sender] * (block.number - investBlock[msg.sender]) * 3 / 590000;
            uint max = raised / 10;
            if (withdraw > max) {
                withdraw = max;
            }
            if (withdraw > 0) {
                msg.sender.transfer(withdraw);
                raised -= withdraw;
                emit FundTransfer(msg.sender, withdraw, false);
            }
        }
        
        raised += msg.value;
        investBlock[msg.sender] = block.number;
        invested[msg.sender] += msg.value;
    }
}