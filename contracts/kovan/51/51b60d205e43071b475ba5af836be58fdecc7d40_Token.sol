/**
 *Submitted for verification at Etherscan.io on 2021-12-30
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.7.0;

contract Token {

    string public name = "My Little Token";
    
    string public symbol = "ATA";

    uint256 public totalSupply = 1000000;
    
    address public owner;
    
    mapping(address => uint256) balances;

    constructor() {
        balances[msg.sender] = totalSupply;
        owner = msg.sender;
    }

    function transfer(address to, uint256 amount) external {
        require(balances[msg.sender] >= amount, "Not enough tokens");
        
        balances[msg.sender] -= amount;
        balances[to] += amount;
    }
    
    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }
}