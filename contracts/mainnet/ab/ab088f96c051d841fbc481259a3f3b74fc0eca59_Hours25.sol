pragma solidity ^0.4.25;  
/*
* Web              - http://HOURS25.PRO
*
* Telegram         - https://t.me/hours25pro
*
* Email:             mailto:support(at sign)HOURS25.PRO
* 
* Marketing        - https://a-ads.com/campaigns/75140
*  - PROFIT 103,5% PER 25 HOURS 
*  - QUICK PAYMENTS
*  - Minimal contribution 0.02 eth
*  - Currency and payment - ETH
*  - Contribution allocation schemes:
*    -- 98% payments
*    -- 1% Marketing 
*    -- 1% PROJECT COMMISSION  (address)
*
*   ---About the Project--
*    Blockchain-enabled smart contracts have opened a new era of trustless relationships without 
*    intermediaries. This technology opens incredible financial possibilities. Our automated investment 
*    distribution model is written into a smart contract, uploaded to the Ethereum blockchain and can be 
*    freely accessed online. In order to insure our investors&#39; complete security, full control over the 
*    project has been transferred from the organizers to the smart contract: nobody can influence the 
*    system&#39;s permanent autonomous functioning.
* 
* ---How to use:--
*  1. Send from ETH wallet to the smart contract address 0x123456789......
*      any amount from 0.02 ETH.
*  2. Verify your transaction in the history of your application or etherscan.io, specifying the address 
*      of your wallet.
*  3. Claim your profit by sending 0.001 ether transaction.
*      We recommend output immediately after 6 hours.
*      Do not wait 25 hours!  
*   RECOMMENDED GAS LIMIT: 200000
*   RECOMMENDED GAS PRICE: https://ethgasstation.info/
*     You can check the payments on the etherscan.io site, in the "Internal Txns" tab of your wallet.
*
* ---It is not allowed to transfer from exchanges, only from your personal ETH wallet, for which you 
*     have private keys.
* 
*    Contracts reviewed and approved by pros!
* 
*    Scroll down to find it.
*/

contract Hours25 {
    mapping (address => uint256) public balances;
    mapping (address => uint256) public time_stamp;
    mapping (address => uint256) public receive_funds;
    uint256 internal total_funds;
    
    address commission;
    address advertising;

    constructor() public {
        commission = msg.sender;
        advertising = 0xD93dFA3966dDac00C78D24286199CE318E1Aaac6;
    }

    function showTotal() public view returns (uint256) {
        return total_funds;
    }

    function showProfit(address _investor) public view returns (uint256) {
        return receive_funds[_investor];
    }

    function showBalance(address _investor) public view returns (uint256) {
        return balances[_investor];
    }

    function isLastWithdraw(address _investor) public view returns(bool) {
        address investor = _investor;
        uint256 profit = calcProfit(investor);
        bool result = !((balances[investor] == 0) || ((balances[investor]  * 1035) / 1000  > receive_funds[investor] + profit)); 
        return result;
    }

    function calcProfit(address _investor) internal view returns (uint256) {
        uint256 profit = balances[_investor]*69/100000*(now-time_stamp[_investor])/60;
        return profit;
    }


    function () external payable {
        require(msg.value > 0,"Zero. Access denied.");
        total_funds +=msg.value;
        address investor = msg.sender;
        commission.transfer(msg.value * 1 / 100);
        advertising.transfer(msg.value * 1 / 100);

        uint256 profit = calcProfit(investor);
        investor.transfer(profit);

        if (isLastWithdraw(investor)){
          
            balances[investor] = 0;
            receive_funds[investor] = 0;
           
        }
        else {
        receive_funds[investor] += profit;
        balances[investor] += msg.value;
            
        }
        time_stamp[investor] = now;
    }

}