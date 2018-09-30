pragma solidity ^0.4.20;

contract Bank {
    // We want an owner that is allowed to selfdestruct.
    address owner;
    mapping (address => uint) balances;
    
    // Constructor
    constructor() public {
        owner = msg.sender;
    }

    // This will take the value of the transaction and add to the senders account.
    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }

    // Attempt to withdraw the given &#39;amount&#39; of Ether from the account.
    function withdraw(uint amount) public {
        require(amount <= balances[msg.sender]);
        balances[msg.sender] -= amount;
        msg.sender.transfer(amount);
    }
    
    function remove() public {
        require(msg.sender == owner);
        selfdestruct(owner);
    }
}