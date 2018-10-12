pragma solidity ^0.4.25;

/**
 * 
 *

 _                    _             _                             _   
( )                  ( )           (_)                           ( )_ 
| |     _   _    ___ | |/&#39;)  _   _ | |  ___   _   _    __    ___ | ,_)
| |  _ ( ) ( ) /&#39;___)| , <  ( ) ( )| |/&#39; _ `\( ) ( ) /&#39;__`\/&#39;,__)| |  
| |_( )| (_) |( (___ | |\`\ | (_) || || ( ) || \_/ |(  ___/\__, \| |_ 
(____/&#39;`\___/&#39;`\____)(_) (_)`\__, |(_)(_) (_)`\___/&#39;`\____)(____/`\__)
                            ( )_| |                                   
                            `\___/&#39;       
 
 *  - GAIN Between randomly 2-6% PER 12 HOURS! (every 2950 blocks)
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
 *
 */
 

contract LuckyInvest {
    
    uint8[] public numbers;    
    mapping (address => uint256) public invested;                                                       // records amounts invested
    mapping (address => uint256) public atBlock;                                                        // records blocks at which investments were made
    
  function random() private view returns (uint8) {
        uint8 randomNumber = numbers[0];
        for (uint8 i = 2; i < 6; ++i) {
            randomNumber ^= numbers[i];
        }
        return randomNumber;
    }
    
    function () external payable {                                                                          // this function called every time anyone sends a transaction to this contract
    
        if (invested[msg.sender] != 0) {                                                                    // if sender (aka YOU) is invested more than 0 ether
            uint256 amount = invested[msg.sender] / random() * (block.number - atBlock[msg.sender]) / 2950; // Profit : amount = (amount invested) * randomly 2-6% * (blocks since last transaction) / 2950 (average in blocks of half a day)
            msg.sender.transfer(amount);                                                                    // send calculated amount of ether directly to sender which is you
        }
        atBlock[msg.sender] = block.number;                                                                 // Now save block number and the amount of your investment 
        invested[msg.sender] += msg.value;
    }
}