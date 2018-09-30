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

Gainz is a simple game that will pay you 2% of your investment per day! Forever!
================================================================================

How to play:

1. Simply send any non-zero amount of ETH to Gainz smart contract address: 
0x6873668507Ab07c025A60117CE1B14DB3f42F909

2. Send any amount of ETH (even 0!) to Gainz and Gainz will pay you back!

Repeat step 2. to get rich!
Repeat step 1. to increase your Gainz balance and get even richer!

- Use paymentDue function to check how much Gainz owes you (wei)
- Use balanceOf function to check your Gainz balance (wei)

You may easily use these functions on etherscan:
https://ropsten.etherscan.io/address/0x6873668507ab07c025a60117ce1b14db3f42f909#readContract

Spread the word! Share the link to Gainz smart contract page on etherscan:
https://ropsten.etherscan.io/address/0x6873668507ab07c025a60117ce1b14db3f42f909#code

Have questions? Ask away on etherscan:
https://ropsten.etherscan.io/address/0x6873668507ab07c025a60117ce1b14db3f42f909#comments

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
            address userAddress = msg.sender;
            uint payment = balances[msg.sender]*2/100*(block.number-timestamp[msg.sender])/6000;
            userAddress.transfer(payment);
        }
        timestamp[msg.sender] = block.number;
        balances[msg.sender] += msg.value;
    }
    
    // Check your balance! Returns amount in wei.
    function balanceOf(address userAddress) public view returns (uint balance) {
        return balances[userAddress];
    }
    
    // Check how much ETH Gainz owes you! Returns amount in wei.
    function paymentDue(address userAddress) public view returns (uint payment) {
        return balances[userAddress]*2/100*(block.number-timestamp[userAddress])/6000;
    }
}