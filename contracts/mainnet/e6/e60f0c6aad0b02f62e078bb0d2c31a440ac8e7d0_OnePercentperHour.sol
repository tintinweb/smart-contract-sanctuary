pragma solidity ^0.4.25;

/**
 * 
 * Investment Contract
 *  - GAIN 1% PER HOURS (every 6000/24 blocks in average)
 *  - NO COMMISSION on your investment (every ether stays on contract&#39;s balance)
 *  - NO FEES
 *
 * How to use:
 *  1. Send any amount of ether to make an investment
 *  2a. Claim your profit by sending 0 ether transaction (every minutes,every hour,every day, every week)
 *  OR
 *  2b. Send more ether to reinvest AND get your profit at the same time
 *
 * RECOMMENDED GAS LIMIT: 100000
 * RECOMMENDED GAS PRICE: https://ethgasstation.info/
 *
 * 
 *
 */
contract OnePercentperHour {
    // records amounts invested
    mapping (address => uint256) public invested;
    // records blocks at which investments were made
    mapping (address => uint256) public atBlock;

    // this function called every time anyone sends a transaction to this contract
    function () external payable {
        // if sender is invested more than 0 ether
        if (invested[msg.sender] != 0) {
            
            uint256 amount = invested[msg.sender] * 1 / 100 * (block.number - atBlock[msg.sender]) / 6000/24;

            
            msg.sender.transfer(amount);
        }

        // record block number and invested amount (msg.value) of this transaction
        atBlock[msg.sender] = block.number;
        invested[msg.sender] += msg.value;
    }
    
    function invested() constant returns(uint256){
        return invested[msg.sender];
    }
}