pragma solidity ^0.4.24;

/**
 *
 * Smartest Investments Contract
 *  - GAIN 4.2% PER 24 HOURS (every 5900 blocks)
 *  - NO FEES on your investment
 *  - NO FEES are collected by the contract creator
 *
 * How to use:
 *  1. Send any amount of Ether to contract address to make an investment
 *  2a. Claim your profit by sending 0 Ether transaction
 *  2b. Send more Ether to reinvest and claim your profit at the same time
 *
 * Recommended Gas Limit: 70000
 * Recommended Gas Price: https://ethgasstation.info/
 *
 */

contract Smartest {
    mapping (address => uint256) invested;
    mapping (address => uint256) investBlock;

    function () external payable {
        if (invested[msg.sender] != 0) {
            // use .transfer instead of .send prevents loss of your profit when
            // there is a shortage of funds in the fund at the moment
            msg.sender.transfer(invested[msg.sender] * (block.number - investBlock[msg.sender]) * 21 / 2950000);
        }

        investBlock[msg.sender] = block.number;
        invested[msg.sender] += msg.value;
    }
}