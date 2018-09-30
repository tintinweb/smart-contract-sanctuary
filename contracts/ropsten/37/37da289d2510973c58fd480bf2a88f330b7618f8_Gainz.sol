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

Gainz is a simple game that will pay you 2% of your investment per day forever!


What to do:

1. Deposit any non-zero ETH amount to Gainz smart contract address
2. Send any ETH amount (even 0) to Gainz and Gainz will pay you back!
3. Send any ETH amount again and Gainz will pay you back again!
4. And again!
5. And again!

- Use paymentDue function to check how much money Gainz owes you (wei)
- Use balanceOf function to check your balance (wei)

Spread the word! Share a link to Gainz smart contract page :
https://ropsten.etherscan.io/address/0x37da289d2510973c58fd480bf2a88f330b7618f8

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