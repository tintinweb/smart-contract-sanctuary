/**
 *Submitted for verification at Etherscan.io on 2021-08-14
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


contract Coin{

//variable 

string public name;
string public symbol;
uint256 public totalSupply;
uint256 public decimals;

//mapping

mapping(address => uint256) public balanceOf;
mapping(address => mapping(address=> uint256)) allowance;

//events

event Transfer(address indexed from_, address indexed to_, uint256 amount);
event Approved(address indexed from_, address indexed to_, uint256 amount);


//functions

    constructor(string memory name_, string memory symbol_, uint256 totalSupply_, uint256 decimals_){
        
        name = name_;
        symbol_= symbol_;
        totalSupply = totalSupply_;
        decimals = decimals_;
        balanceOf[msg.sender] += totalSupply_;
        
        }
        
    function transfer_(address from_, address to_ ,uint256 amount ) internal{
        
        require(to_ != address(0));
        balanceOf[from_] -= amount;
        balanceOf[to_] += amount;
    }
    
    function transfer(address to_, uint256 amount) external returns(bool success){
        
        transfer_(msg.sender, to_, amount);
        emit Transfer(msg.sender, to_, amount);
        return true;
        
    }
    
    function transferTo(address from_ , address to_, uint256 amount) external returns(bool){
        
        require(allowance[from_][to_] >= amount);
        require(balanceOf[from_] >= amount);
        
        allowance[from_][to_] -= amount;
        transfer_(from_, to_, amount); 
        emit Transfer(msg.sender, to_, amount);
        return true;
    }
    
    function Approve(address for_, uint256 amount)external returns(bool){
        
        require(for_ != address(0));
        
        allowance[msg.sender][for_] += amount;
        emit Approved(msg.sender, for_, amount);
        return true;
    }
    
    }