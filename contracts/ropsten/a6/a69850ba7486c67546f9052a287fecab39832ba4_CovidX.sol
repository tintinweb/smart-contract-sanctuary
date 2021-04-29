/**
 *Submitted for verification at Etherscan.io on 2021-04-29
*/

/**
 * SPDX-License-Identifier: UNLICENSED
*/
pragma solidity ^0.8.0;

contract CovidX  {
    
    
    uint256 public totalSupply = 1000000 * (10**18);
    string public name = "CovidX";
    string public symbol = "CVX";
    uint256 public decimals = 18;
    
    mapping (address => mapping (address => uint256)) private allowances;
    mapping (address => uint256) private balances;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    constructor (address payable owner) {
        balances[owner] = totalSupply;
    }
    
    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }
    
    function transfer(address recipient, uint256 amount) public  returns (bool) {
       require(balanceOf(msg.sender) >= amount, "Balance too low!" );
       balances[recipient] += amount;
       balances[msg.sender] -= amount;
       
       emit Transfer(msg.sender, recipient, amount);
        return true;
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
       require(balanceOf(sender) >= amount, "Balance too low!");
       require(allowances[sender][msg.sender] >= amount, "allowances too low!");
       
       balances[recipient] += amount;
       balances[sender] -= amount;
       
       emit Transfer(sender, recipient, amount);
       
        return true;
    }
    
    function approve(address spender, uint256 amount) public returns (bool) {
        allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
}