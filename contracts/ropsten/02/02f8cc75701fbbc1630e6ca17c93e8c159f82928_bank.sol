/**
 *Submitted for verification at Etherscan.io on 2021-04-14
*/

pragma solidity ^0.7;

contract bank {
    mapping (address => uint) private balances;
    address public owner;
    
    constructor() public payable {
        owner = msg.sender;
    }
    
    // User adds tokens to the balance
    // PRE: #deposit > 0
    // RET: balance of the user
    function deposit() public payable returns (uint) {
        require(msg.value > 0);
        balances[msg.sender] = balances[msg.sender] + msg.value;
        return balances[msg.sender];
    }
    
    // User withdraws tokens from the balance
    // PRE: #amount <= #balance (require)
    //      # amount > 0
    function withdraw(uint amount) public payable returns (uint) {
        require(balances[msg.sender] >= amount);
        require(msg.value > 0);
        balances[msg.sender] = balances[msg.sender] - amount;
        msg.sender.transfer(amount);
        return balances[msg.sender];
    }
    
    // User sends token to a different wallet
    // PRE: #tokens <= #balance
    //      # amount > 0
    function transfer(address destination, uint amount) public payable returns (uint) {
        require(amount > 0);
        require(balances[msg.sender] >= amount);
        balances[msg.sender] = balances[msg.sender] - amount;
        payable(destination).transfer(amount);
        return balances[msg.sender];
    }
}