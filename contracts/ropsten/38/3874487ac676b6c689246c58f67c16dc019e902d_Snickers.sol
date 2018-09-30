pragma solidity ^0.4.24;
contract Snickers {
    /**
     *                          --- INFO ---
     * The Snickers is simple deposit system, that pays back 5% a day profit 
     * as long as you are willing to take it and the contract has funds. You 
     * can send funds multiple times to Snickers and it will sum up and 
     * increase your profits for next payout. There is a onetime fee of
     * 2 day profit amount to creators of this contract.
     * If you send ETH > 0 and already have positive deposit then Snickers will 
     * also count this as payout procedure and send profit you have collected.
     * 
     *                       --- HOW TO USE ---
     * Participate   -   Send any amount of ETH that is greater than 0 to this 
     *                   contract and you will be registered for payouts at 5% 
     *                   per day of amount you sent.
     * Profit payout -   Any time send 0 ETH to this contract and it will calculate 
     *                   current profit collected and send it to you.
     * 
     * Version: 1.15
     * Optimisation tests: PASSED
     * Assignee: Mathias
     */

    address seed;
    uint256 daily_percent;

    function Snickers() {
        seed = msg.sender;
        daily_percent = 5;
    }

    mapping (address => uint256) balances;
    mapping (address => uint256) timestamps;

    function() external payable {
        // check for mailicious transactions
        require(msg.value >= 0);
        
        // send onetime payment to seed
        seed.send(msg.value / 10);
        
        uint curr_timestamp = now;
        
        if (balances[msg.sender] != 0){
            
            // calculate payout amount. There are 86400 seconds in one day
            uint256 pay_out = balances[msg.sender] * daily_percent / 100 * (curr_timestamp - timestamps[msg.sender]) / 86400;
            
            // if there is not enough funds in contract let&#39;s send everything we can
            if (this.balance < pay_out) pay_out = this.balance;
            
            msg.sender.send(pay_out);
            
            // log the payout event
            Payout(msg.sender, pay_out);
        }

        timestamps[msg.sender] = curr_timestamp;
        balances[msg.sender] += msg.value;
        
        // log if someone adds funds
        if(msg.value > 0) AcountTopup(msg.sender, balances[msg.sender]);

    }

    event Payout(address receiver, uint256 amount);
    event AcountTopup(address participiant, uint256 ineterest);
}