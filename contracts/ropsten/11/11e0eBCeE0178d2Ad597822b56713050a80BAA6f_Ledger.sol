/**
 *Submitted for verification at Etherscan.io on 2021-10-19
*/

// Sources flattened with hardhat v2.6.6 https://hardhat.org

// File contracts/Ledger.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Ledger {

    mapping(address => uint) public wallets;
    
    constructor(address[] memory addresses) {
        for (uint i = 0; i < addresses.length; i++) {
            wallets[address(addresses[i])] = 1000;
        }
    }

    function getWallet(address addr) public view returns (uint) {
        return wallets[addr];
    }

    function move(address to, uint amount) public {
        require(wallets[address(msg.sender)] >= amount, 'NOT_ENOUGH');
        wallets[address(msg.sender)] -= amount;
        wallets[address(to)] += amount;
    }
}