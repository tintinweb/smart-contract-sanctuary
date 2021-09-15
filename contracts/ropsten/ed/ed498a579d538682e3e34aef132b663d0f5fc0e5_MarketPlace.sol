/**
 *Submitted for verification at Etherscan.io on 2021-09-15
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

contract MarketPlace{
    address buyer;
    address seller;
    mapping(address => uint) public balances;
    
    event ListItem(address seller, uint price);
    event PurchasedItem(address seller, address buyer, uint price);
    
    enum StateType {
        ItemAvailable,
        ItemPurchased
    }
    
    StateType public state;
    
    constructor (){
        seller = msg.sender;
        state = StateType.ItemAvailable;
    }
    
    function buy(address _seller, address _buyer, uint price) public payable {
        require(price < balances[buyer], "Insufficient Balance");
        _buyer = buyer;
        _seller = seller;
        state = StateType.ItemPurchased;
        balances[buyer] -= price;
        balances[seller] += price;
        
        emit PurchasedItem(seller, buyer, msg.value);
    }
}