/**
 *Submitted for verification at Etherscan.io on 2021-07-25
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >= 0.7.0 <0.9.0;

contract ElaineToken {
    
    struct WalletInfo {
        uint totalAmount;
        bool locked;
        bool exist;
    }
    
    uint public totalSupply;
    uint public burnt;
    address public owner;
    mapping(address => WalletInfo) balances;
    
    event SuccessSent(address sender, address receiver, uint amount);
    
    constructor() {
        owner = msg.sender;
        burnt = 0;
        totalSupply += 1000000;
        //newWallet = WalletInfo(1000000,false);
        balances[msg.sender] = WalletInfo(1000000,false,true);
    }
    
    function mint(uint amount) public {
        require(msg.sender == owner);
        totalSupply += amount;
        balances[msg.sender].totalAmount += amount;
    }
    
    function burn(uint amount) public {
        require(msg.sender == owner);
        totalSupply -= amount;
        burnt += amount;
        balances[msg.sender].totalAmount -= amount;
    }
    
    function checkBalance(address wallet) public view returns(uint) {
        return balances[wallet].totalAmount;
    }
    
    function registerWallet(address wallet, bool AllowSend) public {
        balances[wallet] = WalletInfo(0, AllowSend, true);
    }
    
    function checkExist(address sender, address receiver) internal view {
        bool walletExist;
        if (balances[sender].exist == false || balances[receiver].exist == false) {
            walletExist = false;
        } else {
            walletExist = true;
        }
        require(walletExist, "Wallet is not registered");
    }
    
    function checkSufficientBalance(address sender, uint amount) internal view {
        bool sufficient;
        if (balances[sender].totalAmount < amount) {
            sufficient = false;
        } else {
            sufficient = true;
        }
        require(sufficient, "Wallet amount is not sufficient to complete this transaction");
    }
    
    function transfer(address sender, address receiver, uint amount) public {
        require(balances[sender].locked == false, "Sender's wallet is locked");
        checkExist(sender, receiver);
        checkSufficientBalance(sender, amount);
        balances[sender].totalAmount -= amount;
        balances[receiver].totalAmount += amount;
        emit SuccessSent(sender, receiver, amount);
    }
}