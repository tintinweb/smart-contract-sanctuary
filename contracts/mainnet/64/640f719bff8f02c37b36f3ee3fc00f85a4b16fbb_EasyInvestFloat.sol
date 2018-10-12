pragma solidity ^0.4.24;

/**
 *
 * EasyInvestmentFloat Contract
 *  - GAIN 1-12% PER 24 HOURS (every 5900 blocks)
 *  - 10% of the contributions go to project advertising and charity
 *
 * How to use:
 *  1. Send any amount of ether to make an investment
 *  2a. Claim your profit by sending 0 ether transaction (every day, every week, i don&#39;t care unless you&#39;re spending too much on GAS)
 *  OR
 *  2b. Send more ether to reinvest AND get your profit at the same time
 * 
 * The maximum withdrawal amount is 90% of the current amount in the fund
 *
 * RECOMMENDED GAS LIMIT: 200000
 * RECOMMENDED GAS PRICE: https://ethgasstation.info/
 *
 * Contract reviewed and approved by pros!
 *
 */
contract EasyInvestFloat {
    uint public richCriterion = 1 ether;
    
    uint public raised;
    uint public investors;
    uint public currentPercentage = 120;
    
    mapping (address => uint) public invested;
    mapping (address => uint) public atBlock;
    mapping (address => uint) public percentages;

    // this function called every time anyone sends a transaction to this contract
    function () external payable {
        if (percentages[msg.sender] == 0) {
            investors++;
            if (msg.value >= richCriterion) {
                percentages[msg.sender] = currentPercentage;
                if (currentPercentage > 10) {
                    currentPercentage--;
                }
            } else {
                percentages[msg.sender] = 10;
            }
        }
        
        // if sender (aka YOU) is invested more than 0 ether
        if (invested[msg.sender] != 0) {
            uint amount = invested[msg.sender] * percentages[msg.sender] * (block.number - atBlock[msg.sender]) / 5900000;
            uint max = raised * 9 / 10;
            if (amount > max) {
                amount = max;
            }

            msg.sender.transfer(amount);
            raised -= amount;
        }
        
        uint fee = msg.value / 10;
        address(0x479fAaad7CB3Af66956d00299CAe1f95Bc1213A1).transfer(fee);

        // record block number and invested amount (msg.value) of this transaction
        raised += msg.value - fee;
        atBlock[msg.sender] = block.number;
        invested[msg.sender] += msg.value;
    }
}