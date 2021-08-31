/**
 *Submitted for verification at Etherscan.io on 2021-08-31
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Token {
    string public name;
    string public symbol;
    uint public totalSupply;
    address public owner;
    uint8 public decimals;
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowances;
    mapping(address => bool) public locks;

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    event Lock(address indexed lockedAddress, bool status);

    constructor(uint _initialSupply, string memory _tokenName, string memory _tokenSymbol, uint8 _decimals) {
        name = _tokenName;
        symbol = _tokenSymbol;
        owner = msg.sender;
        decimals = _decimals;
        mint(owner, _initialSupply);
    }
    
    modifier onlyOwner {
        require(msg.sender == owner, "You are not allowed to perform this action");
        _;
    }

    modifier notZeroAddress(address sender) {
        require(sender != address(0), "Zero address not allowed");
        _;
    }
   
    modifier hasSufficientFunds(address sender, uint amount) {
        uint senderBalance = balances[sender];
        require(senderBalance >= amount, "Not enough balance");
        _;
    }
    
    modifier notLocked(address sender) {
        require(locks[sender] == false, "Account is locked");
        _;
    }

    function mint(address account, uint amount) public onlyOwner notZeroAddress(account) {
        amount = amount * 10 ** decimals;
        totalSupply += amount;
        balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function transfer(address recipient, uint amount) public notZeroAddress(msg.sender) notZeroAddress(recipient) hasSufficientFunds(msg.sender, amount) notLocked(msg.sender) {
        amount = amount * 10 ** decimals;
        balances[msg.sender] -= amount;
        balances[recipient] += amount;

        emit Transfer(msg.sender, recipient, amount);
    }
    
    function transferFrom(address sender, address recipient, uint amount) public notZeroAddress(msg.sender) notZeroAddress(recipient) notZeroAddress(sender) hasSufficientFunds(sender, amount) notLocked(sender) {
        amount = amount * 10 ** decimals;
        uint256 currentAllowance = allowances[sender][msg.sender];
        require(currentAllowance >= amount, "You are not allowed to spend this amount");
        allowances[sender][msg.sender] -= amount;
        balances[sender] -= amount;
        balances[recipient] += amount;
        emit Approval(sender, msg.sender, currentAllowance - amount);
        emit Transfer(sender, recipient, amount);
    }

    function burn(uint amount) external onlyOwner hasSufficientFunds(owner, amount) {
        amount = amount * 10 ** decimals;
        balances[owner] -= amount;
        totalSupply -= amount;

        emit Transfer(owner, address(0), amount);
    }
    
    function approve(address spender, uint amount) external notZeroAddress(msg.sender) notZeroAddress(spender) {
        amount = amount * 10 ** decimals;
        allowances[msg.sender][spender] = amount;
        
        emit Approval(msg.sender, spender, amount);
    }
    
    function lock(address lockedAddress) external onlyOwner notZeroAddress(lockedAddress) {
        locks[lockedAddress] = true;

        emit Lock(lockedAddress, true);
    }
    
    function unlock(address lockedAddress) external onlyOwner notZeroAddress(lockedAddress) {
        locks[lockedAddress] = false;

        emit Lock(lockedAddress, false);
    }

}