/**
 *Submitted for verification at Etherscan.io on 2021-03-21
*/

pragma solidity ^0.6.0;

contract Bank {
    mapping (address => uint256) public balances;
    address[] accounts;
    uint256 rate = 3; //3% APR
    
    function deposit() public payable {
        if (0 == balances[msg.sender]) {
            accounts.push(msg.sender);
        }
        
        balances[msg.sender] += msg.value;
    }
    
    function withdraw (uint256 amount) public {
        require(balances[msg.sender] >= amount, "Your balance is not enough!");
        balances[msg.sender] -= amount;
        msg.sender.transfer(amount);
    }
    
    function calculateInterest (address user) private view returns (uint256) {
        return balances[user] * rate / 100;
    }
    
    function incraseYear() public {
        for (uint256 i = 0; i < accounts.length; i++) {
            address account = accounts[i];
            uint256 interest = calculateInterest(account);
            balances[account] += interest;
        }
    }
}