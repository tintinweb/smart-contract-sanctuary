/**
 *Submitted for verification at Etherscan.io on 2021-08-26
*/

pragma solidity 0.4.25;

contract Bank {
    address owner;
    int bal;
    
    constructor() public {
        bal = 0;
        owner = msg.sender;
    }
    
    function getBalance() view public returns(int) {
        return bal;
    }
    
    function withdraw(int amount) public {
        require(tx.origin == owner);
        bal = bal - amount;
    }
    
    function deposit(int amount) public {
        bal = bal + amount;
    }
}