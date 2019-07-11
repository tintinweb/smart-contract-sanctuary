/**
 *Submitted for verification at Etherscan.io on 2019-07-09
*/

pragma solidity ^0.5.2;

contract EasterEgg {
    
    /**
     * There&#39;s a high/critical severity bug in subscriptions.sol that allows a malicious actor to
     * drain any account that is in the process of subscribing to a "payNow" subscription. When
     * making the first payment on a subscription we must treat it differently than a later one,
     * so we check if it&#39;s a payNow subscription and if startTime == now then DON&#39;T adjust lastPaid/nextDue.
     * The thing about that is that anyone that gets a payment call (or 50) in after you on the same 
     * block you subscribed will also be able to get a payment through. So a malicious actor can easily
     * drain very many accounts if they felt like it, or trick one welthy person into signing up with them
     * and taking everything.
    **/
    
}