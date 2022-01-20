/**
 *Submitted for verification at polygonscan.com on 2022-01-19
*/

pragma solidity ^0.4.15;


contract WithdrawalContract {

    address public sender;
    address public owner;
    uint public mostSent;

    modifier onlyOwner() {
        require (msg.sender != owner);
        _;

    }

    mapping (address => uint) pendingWithdraws;

    function WithdrawalContract () payable {
        sender = msg.sender;
        mostSent = msg.value;
        owner = msg.sender;
    }

    function pay() payable returns (bool){
        require(msg.value > mostSent);
        pendingWithdraws[sender] += msg.value;
        sender = msg.sender;
        mostSent = msg.value;
        return true;
    }

    function withdraw(uint amount) onlyOwner returns(bool) {
        // uint amount = pendingWithdraws[msg.sender];
        // pendingWithdraws[msg.sender] = 0;
        // msg.sender.transfer(amount);
        require(amount < this.balance);
        owner.transfer(amount);
        return true;

    }

    function getBalance() constant returns(uint){
        return this.balance;
    }

}