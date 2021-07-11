/**
 *Submitted for verification at BscScan.com on 2021-07-10
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

contract StToken {
    mapping(address => uint) private balances;
    mapping(address => mapping(address => uint)) private allowed;
    uint public totalSupply;
    string public name;
    string public symbol;
    uint public decimals;
    
    uint public tax;
    uint public maxTax;
    uint public totalTax;
    
    address public owner;
    address public taxAddress;

    mapping (address => bool) private _isExcludedFromFee;
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    modifier isOwner() {
        require(msg.sender == owner, "Only owner can do this!");
        _;
    }
    
    constructor() {
        name = 'STEST';
        symbol = 'STEST';
        decimals = 18;
        totalSupply = 1000000000 * 10 ** decimals;
        tax = 0;
        maxTax = 20;
        owner = msg.sender;
        _isExcludedFromFee[owner] = true;
        taxAddress = msg.sender;
        totalTax = 0;
        balances[owner] = totalSupply;
        emit Transfer(address(0), owner, totalSupply);
    }
    
    function balanceOf(address _owner) public view returns(uint) {
        return balances[_owner];
    }
    
    function transfer(address to, uint value) public returns(bool) {
        require(balances[msg.sender] >= value, 'Balance is too low');
        
        balances[msg.sender] -= value;
        
        uint taxAmount = 0;
        
        if (tax > 0 && !_isExcludedFromFee[to]) {
            taxAmount = value * tax / 1000;
            
            if (taxAmount > 0) {
                
                totalTax += taxAmount;
                balances[taxAddress] += taxAmount;
                emit Transfer(msg.sender, taxAddress, taxAmount);
            }
        }
        
        value = value - taxAmount;
        
        balances[to] += value;
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint value) public returns(bool) {
        require(balances[from] >= value, 'Balance is too low');
        require(allowed[from][msg.sender] >= value, 'Allowance is too low');
        
        balances[from] -= value;
        allowed[from][msg.sender] -=value;
        
        uint taxAmount = 0;
        
        if (tax > 0 && !_isExcludedFromFee[from] && !_isExcludedFromFee[to]) {
            taxAmount = value * tax / 1000;
            
            if (taxAmount > 0) {
                
                totalTax += taxAmount;
                balances[taxAddress] += taxAmount;
                emit Transfer(from, taxAddress, taxAmount);
            }
        }
        
        value = value - taxAmount;
        
        balances[to] += value;
        emit Transfer(from, to, value);
        return true;   
    }
    
    function approve(address spender, uint value) public returns (bool) {
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;   
    }
    
    function allowance(address _owner, address _spender) public view returns (uint) {
        return allowed[_owner][_spender];
    }
    
    function setTaxAddress(address _newTaxAddress) public isOwner {
        taxAddress = _newTaxAddress;
    }
    
    function setTaxPercent(uint _newTaxPercent) public isOwner {
        require(_newTaxPercent <= maxTax, 'Tax can not be more than 2%');
        tax = _newTaxPercent;
    }
    
    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }
    
    function excludeFromFee(address account) public isOwner {
        _isExcludedFromFee[account] = true;
    }
    
    function includeInFee(address account) public isOwner {
        _isExcludedFromFee[account] = false;
    }

}