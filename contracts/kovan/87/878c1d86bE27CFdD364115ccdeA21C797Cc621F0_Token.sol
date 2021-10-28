/**
 *Submitted for verification at Etherscan.io on 2021-10-28
*/

//SPDX-License-Identifier:MIT 

pragma solidity 0.8.0;


contract Token {
     
    string public name;
    string public symbol;
    uint256 public decimals;
    uint256 public totalsupply;
    
    
    mapping(address => uint)public balance;
    
    event Transfer(address indexed from, address indexed _to, uint _value);
    
    constructor(string memory _name,
                string memory _symbol,
                uint _decimals, uint _totalsupply){
        
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalsupply = _totalsupply;
        balance[msg.sender] = totalsupply;
    }
    
    
    function transfer(address to, uint value)external returns(bool success){
        require(balance[msg.sender] >= value);
        balance[msg.sender] = balance[msg.sender] - (value);
        balance[to] = balance[to] + value;
        emit Transfer(msg.sender, to, value);
        return true;
        
    }
    
}