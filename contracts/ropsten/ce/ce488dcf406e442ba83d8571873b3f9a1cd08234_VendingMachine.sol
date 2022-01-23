/**
 *Submitted for verification at Etherscan.io on 2022-01-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

contract VendingMachine {

    // state variables
    address public owner;
    mapping (address => uint) public hapeBalances;

    // set the owner as th address that deployed the contract
    // set the initial vending machine balance to 100
    constructor() {
        owner = msg.sender;
        hapeBalances[address(this)] = 1000;
    }

    function getVendingMachineBalance() public view returns (uint) {
        return hapeBalances[address(this)];
    }

    // Let the owner restock the vending machine
    function restock(uint amount) public {
        require(msg.sender == owner, "Only the owner can restock.");
        hapeBalances[address(this)] += amount;
    }

    // Purchase hapes from the vending machine
    function purchase(uint amount) public payable {
        require(msg.value >= amount * 0.15 ether, "You must pay at least 0.15 ETH per hape");
        require(hapeBalances[address(this)] >= amount, "Not enough hapes in stock to complete this purchase");
        hapeBalances[address(this)] -= amount;
        hapeBalances[msg.sender] += amount;
    }
}