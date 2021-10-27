/**
 *Submitted for verification at Etherscan.io on 2021-10-27
*/

//SPDX-License-Identifier:MIT 


pragma solidity ^0.8.0;


contract MyToken{
    string public name;
    string public symbol;
    uint256 public decimal;
    uint256 public totalsupply;
    
    
    event Transfer(address indexed from, address indexed _to, uint indexed _value);
    
    mapping(address => uint)public balance;
    
    constructor(string memory _name, 
                string memory _symbol, 
                uint _decimal, 
                uint _totalsupply){
                    
            name = _name;
            symbol = _symbol;
            decimal = _decimal;
            totalsupply = _totalsupply;
            balance[msg.sender] = totalsupply;
    }
    
    
    function transfer(address to, uint256 value)external  returns(bool success){
        require(balance[msg.sender] >= value);
        balance[msg.sender] = balance[msg.sender] - (value);
        balance[to] = balance[to] + (value);
        emit Transfer(msg.sender, to, value);
        return true;
        
        
    }
    
    
}