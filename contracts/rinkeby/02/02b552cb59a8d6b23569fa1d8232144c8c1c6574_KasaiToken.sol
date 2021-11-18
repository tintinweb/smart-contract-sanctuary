/**
 *Submitted for verification at Etherscan.io on 2021-11-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function totalSupply() external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract KasaiToken is IERC20 {
    string public tokenName;
    string public tokenSymbol;
    uint256 public supply;
    
    mapping(address => uint256) public balances;
    mapping(address /*from Alice*/ => mapping(address /*msg.sender*/ => uint256 /*value*/)) public allowances;
    
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _totalSupply
    ) {
        tokenName = _name;
        tokenSymbol = _symbol;
        supply = _totalSupply;
        
        balances[msg.sender] = _totalSupply;
    }
    
    function name() external view override(IERC20) returns (string memory) {
        return tokenName;
    }
    
    function symbol() external view override(IERC20) returns (string memory) {
        return tokenSymbol;
    }
    
    function totalSupply() external view override(IERC20) returns (uint256) {
        return supply;
    }
    
    function balanceOf(address owner) external view override(IERC20) returns (uint256) {
        return balances[owner];
    }
    
    function transfer(address to, uint256 value) external override(IERC20) returns (bool) {
        require(balances[msg.sender] >= value, "not enough balance");
        balances[msg.sender] -= value;
        balances[to] += value;
        
        // fire event
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint256 value) external override(IERC20) returns (bool) {
        require(balances[from] >= value, "not enough balance");
        
        uint256 _allowance = allowances[from][msg.sender];
        require(_allowance >= value, "not enough allowance");
        
        allowances[from][msg.sender] -= value;
        balances[from] -= value;
        balances[to] += value;
        
        emit Transfer(from, to, value);
        return true;
    }
    
    function approve(address spender, uint256 value) external override(IERC20) returns (bool) {
        require(spender != msg.sender, "connot self approve");
        
        allowances[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    
    function allowance(address owner, address spender) external view override(IERC20) returns (uint256) {
        return allowances[owner][spender];
    }
}