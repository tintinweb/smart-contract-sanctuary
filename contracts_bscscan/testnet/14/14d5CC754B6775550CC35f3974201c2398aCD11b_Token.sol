/**
 *Submitted for verification at BscScan.com on 2022-01-01
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;
contract Token {
    string public name = "Brian Coin";
    
    string public symbol = "BRC";

    uint256 public totalSupply = 1000000;
    
    address public owner;

    mapping ( address => uint256 ) balances;

    constructor()  {
        owner = msg.sender;
        balances[msg.sender] = totalSupply ; 
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