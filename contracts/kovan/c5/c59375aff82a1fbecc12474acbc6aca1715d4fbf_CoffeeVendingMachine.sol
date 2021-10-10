/**
 *Submitted for verification at Etherscan.io on 2021-10-10
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract CoffeeVendingMachine {
    event CoffeOrdered(address _customer, string position);
    
    uint256 public cofMaked = 0;
    
    string[] public assortment = ["Espresso", "Latte", "Americano"];
    
    address payable public owner;
    
    constructor() {
        owner = payable(msg.sender);
    }
    
    modifier costs(uint256 _amount) {
        require(msg.value >= _amount, "Not enugh ether provided");
        _;
    }
    
    function getCoffee(uint256 _type) public payable {
        require(_type > 0 && _type < 4, "Wrong position ordered");
        if (_type == 1) {
            require(msg.value >= 0.0001 ether);
            owner.transfer(msg.value);
        } else if (_type == 2) {
            require(msg.value >= 0.0003 ether);
            owner.transfer(msg.value);
        } else {
            require(msg.value >= 0.0002 ether);
            owner.transfer(msg.value);
        }
        emit CoffeOrdered(msg.sender, assortment[_type - 1]);
        cofMaked += 1;
    }
}