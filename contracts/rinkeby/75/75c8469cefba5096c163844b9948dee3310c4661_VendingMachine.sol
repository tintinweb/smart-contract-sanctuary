/**
 *Submitted for verification at Etherscan.io on 2021-06-21
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.5;

contract VendingMachine {
    address public owner;
    uint256 public price;
    mapping(address => uint256) public cupcakeBalances;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call");
        _;
    }

    constructor() {
        owner = msg.sender;
        price = 1 ether;
        cupcakeBalances[address(this)] = 100;
    }

    function refill(uint256 amount) public onlyOwner {
        cupcakeBalances[address(this)] += amount;
    }

    function changePrice(uint256 newPrice) public onlyOwner {
        price = newPrice;
    }

    function purchase(uint256 amount) public payable {
        require(msg.value == amount * price, "Incorrect price");
        require(cupcakeBalances[address(this)] >= amount, "Not enough cupcakes in stock to complete this purchase");
        cupcakeBalances[address(this)] -= amount;
        cupcakeBalances[msg.sender] += amount;
        payable(owner).transfer(msg.value);
    }
}