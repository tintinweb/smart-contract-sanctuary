/**
 *Submitted for verification at Etherscan.io on 2021-04-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

contract WeiConvertibleToken {
    mapping (address => uint256) public balanceOf;
    
    event Transfer(address indexed _from, address indexed _to, uint256 value);
    
    string public name;
    string public symbol;
    uint256 public totalSupply;
    uint256 public tokenPrice;
    
    constructor() {
        name = "Wei Convertible Token";
        symbol = "WECT";
        totalSupply = 0;
        tokenPrice = 1;
        
        balanceOf[address(this)] = totalSupply;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(balanceOf[msg.sender] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        
        emit Transfer(msg.sender, _to, _value);
        
        return true;
    }
    
    function buy() payable public returns (uint amount) {
        amount = msg.value / tokenPrice;
        
        balanceOf[msg.sender] += amount;
        totalSupply += amount;
        
        emit Transfer(address(this), msg.sender, amount);

        return amount;
    }

    function sell(uint amount) public returns (uint revenue) {
        require(balanceOf[msg.sender] >= amount);
        
        balanceOf[msg.sender] -= amount;
        totalSupply -= amount;
        
        revenue = amount * tokenPrice;
        
        require(payable(address(msg.sender)).send(revenue));
        
        emit Transfer(msg.sender, address(this), amount);

        return revenue;
    }
}