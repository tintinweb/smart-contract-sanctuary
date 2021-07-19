/**
 *Submitted for verification at BscScan.com on 2021-07-19
*/

pragma solidity ^0.8.4;

contract BNB_Storage {
    address public owner;
    mapping (address => uint) public balances;

    event Withdraw(address to, uint amount);
    
    constructor() public {
        owner = msg.sender;
    }
    
    function DepositBNB() public payable{
         balances[msg.sender] += msg.value;
    }
    function WithdrawBNB(address receiver, uint amount) public {
        if (balances[msg.sender] < amount) return;
        balances[msg.sender] -= amount;
        balances[receiver] += amount;
        emit Withdraw(msg.sender, amount);
    }
}