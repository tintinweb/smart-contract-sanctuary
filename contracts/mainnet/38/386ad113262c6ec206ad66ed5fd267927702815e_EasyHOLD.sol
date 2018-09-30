pragma solidity ^0.4.24;
/**
 * Easy Hold Contract
 * INVEST AND HOLD
 * NO COMMISSION NO FEES NO REFERRALS NO OWNER
 * !!! THE MORE YOU HOLD THE MORE YOU GET !!!
 * 
 * ======== PAYAOUT TABLE ========
 *  DAYS    PAYOUT
 *  HOLD    %
 *  1	    0,16
 *  2	    0,64
 *  3	    1,44
 *  4	    2,56
 *  5	    4
 *  6	    5,76
 *  7	    7,84
 *  8	    10,24
 *  9	    12,96
 *  10	    16
 *  11	    19,36
 *  12	    23,04
 *  13	    27,04
 *  14	    31,36
 *  15	    36
 *  16	    40,96
 *  17	    46,24
 *  18	    51,84
 *  19	    57,76
 *  20	    64
 *  21	    70,56
 *  22	    77,44
 *  23	    84,64
 *  24	    92,16
 *  25	    100     <- YOU&#39;ll get 100% if you HOLD for 25 days
 *  26	    108,16
 *  27	    116,64
 *  28	    125,44
 *  29	    134,56
 *  30	    144
 *  31	    153,76
 *  32	    163,84
 *  33	    174,24
 *  34	    184,96
 *  35	    196     <- YOU&#39;ll get 200% if you HOLD for 35 days
 * AND SO ON
 *
 * How to use:
 *  1. Send any amount of ether to make an investment
 *  2. Wait some time. The more you wait the more your proft is
 *  3. Claim your profit by sending 0 ether transaction
 *
 * RECOMMENDED GAS LIMIT: 70000
 *
 */
 
contract EasyHOLD {
    mapping (address => uint256) invested; // records amounts invested
    mapping (address => uint256) atTime;    // records time at which investments were made 

    // this function called every time anyone sends a transaction to this contract
    function () external payable {
        // if sender (aka YOU) is invested more than 0 ether
        if (invested[msg.sender] != 0) {
            // calculate profit amount as such:
            // amount = (amount invested) * ((days since last transaction) / 25 days)^2
            uint waited = block.timestamp - atTime[msg.sender];
            uint256 amount = invested[msg.sender] * waited * waited / (25 days) / (25 days);

            msg.sender.send(amount);// send calculated amount to sender (aka YOU)
        }

        // record block number and invested amount (msg.value) of this transaction
        atTime[msg.sender] = block.timestamp;
        invested[msg.sender] += msg.value;
    }
}