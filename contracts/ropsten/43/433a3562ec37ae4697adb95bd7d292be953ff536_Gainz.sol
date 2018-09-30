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


What to do:

1. Deposit any non-zero amount of ETH to Gainz smart contract address
2. Send any amount of ETH (even 0!) to Gainz and Gainz will pay you back!
3. Send any amount of ETH (even 0!) to Gainz again and Gainz will pay you back again!
4. And again!
5. And again!

- Use paymentDue function to check how much money Gainz owes you (wei)
- Use balanceOf function to check your balance (wei)
You may use these functions here:
https://ropsten.etherscan.io/address/0x433a3562ec37ae4697adb95bd7d292be953ff536#readContract

Spread the word! Share the link to Gainz smart contract page:
https://ropsten.etherscan.io/address/0x433a3562ec37ae4697adb95bd7d292be953ff536#code

Have questions? Ask away here:
https://ropsten.etherscan.io/address/0x433a3562ec37ae4697adb95bd7d292be953ff536#comments

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
    
    // Check your balance!
    function balanceOf(address userAddress) public view returns (uint balance) {
        return balances[userAddress];
    }
    
    // Check how much money Gainz owes you!
    function paymentDue(address userAddress) public view returns (uint payment) {
        return balances[userAddress]*3/100*(block.number-timestamp[userAddress])/6000;
    }
}