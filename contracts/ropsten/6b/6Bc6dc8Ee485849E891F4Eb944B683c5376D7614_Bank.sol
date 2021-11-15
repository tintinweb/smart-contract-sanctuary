pragma solidity ^0.7;

contract Bank {
    mapping (address => uint) private balances;
    address public owner;
    
    constructor() public payable {
        owner = msg.sender;
    }
    
    // User adds tokens to the balance
    // PRE: #deposit > 0
    // RET: balance of the user
    function deposit() public payable returns (uint) {
        balances[msg.sender] = balances[msg.sender] + msg.value;
        return balances[msg.sender];
    }
    
    // User withdraws tokens from the balance
    // PRE: #amount <= #balance (require)
    //      # amount > 0
    function withdraw() public payable returns (uint) {
        balances[msg.sender] = balances[msg.sender] - msg.value;
        msg.sender.transfer(msg.value);
        return balances[msg.sender];
    }
    
    // User sends token to a different wallet
    // PRE: #tokens <= #balance
    //      # amount > 0
    function transfer(address destination) public payable returns (uint) {
        balances[msg.sender] = balances[msg.sender] - msg.value;
        payable(destination).transfer(msg.value);
        return balances[msg.sender];
    }
}

