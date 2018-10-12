/*
* ETHEREUM ACCUMULATIVE SMARTCONTRACT
* Web              - https://highfiveeth.org
* Twitter          - https://twitter.com/highfiveeth
* Telegram_channel - https://t.me/highfiveeth
* EN  Telegram_chat: https://t.me/highfiveeth_en		
* RU  Telegram_chat: https://t.me/highfiveeth_ru
* CN  Telegram_chat: https://t.me/highfiveeth_cn
* 
*  - GAIN 4-5% OF YOUR DEPOSIT  PER 24 HOURS (every 5900 blocks)
*  - 4% IF YOUR TOTAL DEPOSIT 0.01-1 ETH
*  - 4.25% IF YOUR TOTAL DEPOSIT 1-10 ETH
*  - 4.5% IF YOUR TOTAL DEPOSIT 10-20 ETH
*  - 4.75% IF YOUR TOTAL DEPOSIT 20-40 ETH
*  - 5% IF YOUR TOTAL DEPOSIT 40+ ETH
*  - Life-long payments
*  - The revolutionary reliability
*  - Minimal contribution is 0.01 eth
*  - Currency and payment - ETH
*  - !!!It is not allowed to transfer from exchanges, only from your personal ETH wallet!!!
*  - Contribution allocation schemes:
*    -- 88% payments
*    -- 12% Marketing + Operating Expenses
*
*   ---About the Project
*  Blockchain-enabled smart contracts have opened a new era of trustless relationships without 
*  intermediaries. This technology opens incredible financial possibilities. Our automated investment 
*  distribution model is written into a smart contract, uploaded to the Ethereum blockchain and can be 
*  freely accessed online. In order to insure our investors&#39; complete security, full control over the 
*  project has been transferred from the organizers to the smart contract: nobody can influence the 
*  system&#39;s permanent autonomous functioning.
* 
* ---How to use:
*  1. Send from ETH wallet to the smart contract address "0x7c2d76735b09de69c1ead5849b3a5176fa688f4a"
*     any amount above 0.01 ETH.
*  2. Verify your transaction in the history of your application or etherscan.io, specifying the address 
*     of your wallet.
*  3a. Claim your profit by sending 0 ether transaction 
*  OR
*  3b. For reinvest, you need first to remove the accumulated percentage of charges (by sending 0 ether 
*      transaction), and only after that, deposit the amount that you want to reinvest.
*  
* RECOMMENDED GAS LIMIT: 200000
* RECOMMENDED GAS PRICE: https://ethgasstation.info/
* You can check the payments on the etherscan.io site, in the "Internal Txns" tab of your wallet.
*
* 
* Contracts reviewed and approved by pros!
*/
pragma solidity ^0.4.25;

contract Highfiveeth {
    mapping (address => uint256) invested;
    mapping (address => uint256) atBlock;
    uint256 minValue; 
    address owner1;    // 10%
    address owner2;    // 1%
    address owner3;    // 1%
    event Withdraw (address indexed _to, uint256 _amount);
    event Invested (address indexed _to, uint256 _amount);
    
    constructor () public {
        owner1 = 0xA20AFFf23F2F069b7DE37D8bbf9E5ce0BA97989C;    // 10%
        owner2 = 0x9712dF59b31226C48F1c405E7C7e36c0D1c00031;    // 1%
        owner3 = 0xC0a411924b146c19e8E07c180aeE4cC945Cc28a2;    // 1%
        minValue = 0.01 ether; //min amount for transaction
    }
    
    /**
     * This function calculated percent
     * less than 1 Ether    - 4.0  %
     * 1-10 Ether           - 4.25 %
     * 10-20 Ether          - 4.5  %
     * 20-40 Ether          - 4.75 %
     * more than 40 Ether   - 5.0  %
     */
        function getPercent(address _investor) internal view returns (uint256) {
        uint256 percent = 400;
        if(invested[_investor] >= 1 ether && invested[_investor] < 10 ether) {
            percent = 425;
        }

        if(invested[_investor] >= 10 ether && invested[_investor] < 20 ether) {
            percent = 450;
        }

        if(invested[_investor] >= 20 ether && invested[_investor] < 40 ether) {
            percent = 475;
        }

        if(invested[_investor] >= 40 ether) {
            percent = 500;
        }
        
        return percent;
    }
    
    /**
     * Main function
     */
    function () external payable {
        require (msg.value == 0 || msg.value >= minValue,"Min Amount for investing is 0.01 Ether.");
        
        uint256 invest = msg.value;
        address sender = msg.sender;
        //fee owners
        owner1.transfer(invest / 10);
        owner2.transfer(invest / 100);
        owner3.transfer(invest / 100);
            
        if (invested[sender] != 0) {
            uint256 amount = invested[sender] * getPercent(sender) / 10000 * (block.number - atBlock[sender]) / 5900;

            //fee sender
            sender.transfer(amount);
            emit Withdraw (sender, amount);
        }

        atBlock[sender] = block.number;
        invested[sender] += invest;
        if (invest > 0){
            emit Invested(sender, invest);
        }
    }
    
    /**
     * This function show deposit
     */
    function showDeposit (address _deposit) public view returns(uint256) {
        return invested[_deposit];
    }

    /**
     * This function show block of last change
     */
    function showLastChange (address _deposit) public view returns(uint256) {
        return atBlock[_deposit];
    }

    /**
     * This function show unpayed percent of deposit
     */
    function showUnpayedPercent (address _deposit) public view returns(uint256) {
        uint256 amount = invested[_deposit] * getPercent(_deposit) / 10000 * (block.number - atBlock[_deposit]) / 5900;
        return amount;
    }


}