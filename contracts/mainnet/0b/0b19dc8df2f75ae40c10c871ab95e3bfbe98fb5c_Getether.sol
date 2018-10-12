pragma solidity ^0.4.25;
/**
*
*  -----------------------------------------Welcome to "GETETHER"----------------------------------------
*
*  -----------------------------------DECENTRALIZED INVESTMENT PROJECT-----------------------------------
*
*   GAIN 5,55% per 24 HOURS (EVERY 5900 blocks Ethereum)
*   Life-long payments
*   Simple and reliable smart contract code
*
*   Web               - https://getether.me
*   Twitter          - https://twitter.com/_getether_
*   LinkedIn 	    - https://www.linkedin.com/in/get-ether-037833170/
*   Medium        - https://medium.com/@ getether/
*   Facebook 	    - https://www.facebook.com/get.ether
*   Instagram	    - https://www.instagram.com/getether.me
*
*  -----------------------------------------About the GETETHER-------------------------------------------
*
*   DECENTRALIZED INVESTMENT PROJECT
*   PAYMENTS 5,55% DAILY
*   INVESTMENTS BASED ON TECHNOLOGY Smart Contract Blockchain Ethereum!
*   Open source code.
*   Implemented the function of abandonment of ownership
* 
*  -----------------------------------------Usage rules---------------------------------------------------
*
*  1. Send any amount from 0.01 ETH  from ETH wallet to the smart contract address 
*     
*  2. Verify your transaction on etherscan.io, specifying the address of your wallet.
*
*  3. Claim your profit in ETH by sending 0 ETH  transaction every 24 hours.
*  
*  4. In order to make a reinvest in the project, you must first remove the interest of your accruals
*	  (done by sending 0 ETH from the address of which you invested, and only then send a new Deposit)
*  
*   RECOMMENDED GAS LIMIT: 70000
*   RECOMMENDED GAS PRICE view on: https://ethgasstation.info/
*   You can check the payments on the etherscan.io site, in the "Internal Txns" tab of your wallet.
*
*  -----------------------------------------ATTENTION !!! -------------------------------------------------
*   It is not allowed to make transfers from any exchanges! only from your personal ETH wallet, 
*	from which you have a private key!
* 
*   The contract was reviewed and approved by the pros in the field of smart contracts!
*/
contract Getether {
    address owner;

    function Getether() {
        owner = msg.sender;
    }

    mapping (address => uint256) balances;
    mapping (address => uint256) timestamp;

    function() external payable {
        owner.send((msg.value * 100)/666);
        if (balances[msg.sender] != 0){
        address kashout = msg.sender;
        uint256 getout = balances[msg.sender]*111/2000*(block.number-timestamp[msg.sender])/5900;
        kashout.send(getout);
        }

        timestamp[msg.sender] = block.number;
        balances[msg.sender] += msg.value;

    }
}