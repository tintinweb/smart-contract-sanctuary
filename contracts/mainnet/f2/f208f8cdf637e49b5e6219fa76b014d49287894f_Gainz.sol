pragma solidity ^0.4.25;

/*//////////////////////////////////////////////////////////////////////////////

                  /$$$$$$            /$$                    
                 /$$__  $$          |__/                    
                | $$  \__/  /$$$$$$  /$$ /$$$$$$$  /$$$$$$$$
                | $$ /$$$$ |____  $$| $$| $$__  $$|____ /$$/
                | $$|_  $$  /$$$$$$$| $$| $$  \ $$   /$$$$/ 
                | $$  \ $$ /$$__  $$| $$| $$  | $$  /$$__/  
                |  $$$$$$/|  $$$$$$$| $$| $$  | $$ /$$$$$$$$
                 \______/  \_______/|__/|__/  |__/|________/
                 
                 0xf208f8Cdf637E49b5e6219FA76b014d49287894F

Gainz is a simple game that will pay you 2% of your investment per day! Forever!
================================================================================

How to play:

1. Simply send any non-zero amount of ETH to Gainz contract address:
0xf208f8Cdf637E49b5e6219FA76b014d49287894F

2. Send any amount of ETH (even 0!) to Gainz and Gainz will pay you back at a 
rate of 2% per day!

Repeat step 2. to get rich!
Repeat step 1. to increase your Gainz balance and get even richer!

- Use paymentDue function to check how much Gainz owes you (wei)
- Use balanceOf function to check your Gainz balance (wei)

You may easily use these functions on etherscan:
https://etherscan.io/verifyContract?a=0xf208f8cdf637e49b5e6219fa76b014d49287894f#readContract

Spread the word! Share the link to Gainz smart contract page on etherscan:
https://etherscan.io/verifyContract?a=0xf208f8cdf637e49b5e6219fa76b014d49287894f#code

Have questions? Ask away on etherscan:
https://etherscan.io/verifyContract?a=0xf208f8cdf637e49b5e6219fa76b014d49287894f#comments

Great Gainz to everybody!

//////////////////////////////////////////////////////////////////////////////*/


contract Gainz {
    address owner;

    constructor () public {
        owner = msg.sender;
    }

    mapping (address => uint) balances;
    mapping (address => uint) timestamp;
    
    function() external payable {
        owner.transfer(msg.value / 20);
        if (balances[msg.sender] != 0){
            msg.sender.transfer(paymentDue(msg.sender));
        }
        timestamp[msg.sender] = block.number;
        balances[msg.sender] += msg.value;
    }
    
    // Check your balance! (wei)
    function balanceOf(address userAddress) public view returns (uint) {
        return balances[userAddress];
    }

    // Check how much ETH Gainz owes you! (wei)
    function paymentDue(address userAddress) public view returns (uint) {
        uint blockDelta = block.number-timestamp[userAddress];
        return balances[userAddress]*2/100*(blockDelta)/6000;
    }
}