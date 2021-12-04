// SPDX-License-Identifier: GPL-3.0

// Created by HolaNext

pragma solidity ^0.8.2;

contract Just{
    uint public mintCounter = 1;
    uint public factor = 111;
    uint public prizeMoney;
    uint public price;
    uint public balance;
    uint public just;
    uint public toAdd;

    constructor(){
        price = 1 ether/100;
    }

    function mint(uint256 amount) external{

        price += amount;
    }

    function withdraw() external {

        require(balance > prizeMoney * 1 ether/100);
        just +=1;
    }
}