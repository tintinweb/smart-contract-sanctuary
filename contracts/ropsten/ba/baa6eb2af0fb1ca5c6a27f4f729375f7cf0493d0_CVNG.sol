/**
 *Submitted for verification at Etherscan.io on 2021-08-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

// Safe math
contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || b == c/a);
    }
    
    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require (b != 0);
        c = a / b;
    }
}

// ERC-20 interface

abstract contract ERC20Interface {
    function totalSupply() public view virtual returns (uint);
    function balanceOf(address owner) public view virtual returns (uint balance);
    function allowance(address owner, address spender) public virtual view returns (uint allowedTokens);
    function approve(address spender, uint amount) public virtual returns (bool success);
    function transfer(address to, uint amount) public virtual returns (bool success);
    function transferFrom(address from, address to, uint amount) public virtual returns (bool success);
    
    event Transfer(address indexed from, address indexed to, uint amount);
    event Approval(address indexed owner, address indexed spender, uint amount);
}

//Contract function to receive approval and execute function in one call
 
abstract contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 amount, address token, bytes memory data) public virtual;
}
 
//Actual token contract

contract CVNG is ERC20Interface, SafeMath {
    string public sympbol = "CVNG";
    string public  name = "Cuong's first ERC-20-compliant token";
    uint8 public decimals = 8;
    uint public _totalSupply = 1e6;
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    
    constructor() public {
        address MY_ADDRESS = 0x40eD1BbA741dc7d185577e93256f5dCA33cf1266;
        balances[MY_ADDRESS] = _totalSupply;
        emit Transfer(address(0), MY_ADDRESS, _totalSupply);
    }
    
    function totalSupply() public view override returns (uint) {
        return safeSub(_totalSupply, balances[address(0)]);
    }
    
    function balanceOf(address owner) public override view returns (uint balance) {
        return balances[owner];
    }     
    
    function allowance(address owner, address spender) override public view returns (uint allowedTokens) {
        return allowed[owner][spender];
    }
    
    function approve(address spender, uint amount) override public returns (bool success){
        allowed[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    
    function transfer(address to, uint amount) override public returns (bool success){
        balances[msg.sender] = safeSub(balances[msg.sender], amount);
        balances[to] = safeAdd(balances[to], amount);
        emit Transfer(msg.sender, to, amount);
        return true;
    }
    
    function transferFrom(address from, address to, uint amount) public override returns (bool success) {
        balances[from] = safeSub(balances[from], amount);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], amount);
        balances[to] = safeAdd(balances[to], amount);
        emit Transfer(from, to, amount);
        return true;
    }
    
    function approveAndCall(address spender, uint amount, bytes memory data) public returns (bool success) {
        allowed[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, amount, address(this), data);
        return true;
    }
    
    // fallback () external payable {
    //     revert();
    // }
    
}