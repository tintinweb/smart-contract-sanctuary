/**
 *Submitted for verification at Etherscan.io on 2021-04-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface ERC20
{
    function totalSupply() external view returns (uint256);
    function balanceOf(address tokenOwner) external view returns (uint);
    function allowance(address tokenOwner, address spender) external view returns (uint);
    function transfer(address to, uint tokens) external returns (bool);
    function approve(address spender, uint tokens)  external returns (bool);
    function transferFrom(address from, address to, uint tokens) external returns (bool);
}

contract TokenDemo is ERC20 {
    uint256 totalSuply;
    string name;
    string symbol;
    address owner;
    mapping(address => uint256) balance;
    mapping(address => mapping(address => uint256)) allowed;
    constructor(string memory _name,string memory _symbol, uint256 _totalsupply){
        name = _name;
        symbol=_symbol;
        totalSuply = _totalsupply;
        balance[msg.sender] = _totalsupply;
        owner = msg.sender;
    }
    
    
    function totalSupply() external override view returns (uint256){
        return totalSuply;   
    }
    function balanceOf(address tokenOwner) external override view returns (uint){
        return balance[tokenOwner];
        
    }
    function allowance(address tokenOwner, address spender) external override view returns (uint){
        return allowed[tokenOwner][spender];
    }
    function transfer(address to, uint tokens) external override returns (bool){
        
        balance[owner] -= tokens;
        balance[to] += tokens;
        return true;
    }
    function approve(address spender, uint tokens)  external override returns (bool){
        
        return true;
    }
    function transferFrom(address from, address to, uint tokens) external override returns (bool){
        return true;
    }
    
    
    
}