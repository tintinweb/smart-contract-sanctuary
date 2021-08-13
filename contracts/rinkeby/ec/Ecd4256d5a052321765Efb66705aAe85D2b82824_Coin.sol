/**
 *Submitted for verification at Etherscan.io on 2021-08-13
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


contract Coin {
   
   //variables

    string public name;
    string public symbol;
    uint public totalSupply;
    uint public decimals;
    
    
    //mappping
    
    mapping(address => uint) balanceOf;
    mapping(address => mapping(address => uint)) allowance;
    
    //events
    
    event Transfer (address _from, address _to, uint amount);
    event Approval(address _from, address _to, uint amount);
    
    //functions
    
    constructor(string memory name_, string memory symbol_, uint decimals_, uint totalSupply_){
        
        name = name_;
        symbol = symbol_;
        totalSupply = totalSupply_;
        decimals = decimals_;
    }
    
    function transfer_ (address _from, address _to, uint amount) internal{
        
        require(_to != address(0));
        balanceOf[_from] -= amount;
        balanceOf[_to] += amount;
    } 
    
    function transfer(address to, uint amount) external returns(bool success){
        
        require(balanceOf[msg.sender] >= amount);
        
        transfer_(msg.sender, to, amount);
        emit Transfer(msg.sender, to, amount);
        return true;
    }
    
    function aprove(address spender, uint amount) external returns(bool){
        require(balanceOf[msg.sender] >= amount);
        require(spender != address(0));
        
        allowance[msg.sender][spender] += amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    
    function transferTo(address from_ ,address to_, uint amount) external returns(bool){
        
        require(balanceOf[from_] >= amount);
        require(allowance[from_][to_] >= amount);
        
        allowance[from_][to_] -= amount;
        transfer_(from_, to_, amount);
        emit Transfer(from_, to_, amount);
        return true;
    }
}