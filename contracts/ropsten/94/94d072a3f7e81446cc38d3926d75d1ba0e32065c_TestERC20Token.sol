/**
 *Submitted for verification at Etherscan.io on 2021-02-19
*/

// SPDX-License-Identifier: MIT


pragma solidity ^0.6.10;

contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a); c = a - b; } function safeMul(uint a, uint b) public pure returns (uint c) { c = a * b; require(a == 0 || c / a == b); } function safeDiv(uint a, uint b) public pure returns (uint c) { require(b > 0);
        c = a / b;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address to, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract TestERC20Token is IERC20,SafeMath {
    address contractOwner;
    
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor () public {
       contractOwner = msg.sender;
        _name = "Pide Token";
        _symbol = "PIDE";
        _decimals = 18;
        _totalSupply = 100000000000;
        _balances[contractOwner] = _totalSupply;
        emit Transfer(address(0), contractOwner, _balances[contractOwner]);
    }
    
    function totalSupply() override public view returns (uint256) {
        return _totalSupply;
    }
    
    function balanceOf(address account) override public view returns (uint256) {
        return _balances[account];
    }
    
    function symbol() override public view returns (string memory) {
        return _symbol;
    }
    
    function name() override public view returns (string memory){
        return _name;
    }
    
    function transfer(address recipient, uint256 amount) override public returns (bool){
        _balances[msg.sender] = safeSub(_balances[msg.sender], amount);
        _balances[recipient] = safeAdd(_balances[recipient], amount);
    
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }
    
    function allowance(address owner, address spender) override public view returns (uint256) {
        return _allowances[owner][spender];
    }
    
    // approve tokens to be redeamed by the spender when they want
    function approve(address spender, uint256 amount) override public returns (bool){
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    
    // tranfers allowed tokens from sender to other address (needs to be executed by the allowed account)
    function transferFrom(address sender, address to, uint amount) override public returns (bool){
        _balances[sender] = safeSub(_balances[sender], amount);
        _allowances[sender][msg.sender] = safeSub(_allowances[sender][msg.sender], amount);
        _balances[to] = safeAdd(_balances[to], amount);
    	emit Transfer(sender, to, amount);

        return true;
    }
    
}