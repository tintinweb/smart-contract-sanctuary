/**
 *Submitted for verification at Etherscan.io on 2021-10-28
*/

//SPDX-License-Identifier:MIT 

pragma solidity 0.8.0;


contract Token {
     
    string public name;
    string public symbol;
    uint256 public decimals;
    uint256 public totalSupply;
    
    
    mapping(address => uint)public balanceOf;
    
    event Transfer(address indexed from, address indexed _to, uint _value);
    
    constructor(string memory _name,
                string memory _symbol,
                uint _decimals, uint _totalSupply){
        
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalSupply;
        balanceOf[msg.sender] = totalSupply;
    }
    
    
    function transfer(address to, uint value)external returns(bool success){
        require(balanceOf[msg.sender] >= value);
        balanceOf[msg.sender] = balanceOf[msg.sender] - (value);
        balanceOf[to] = balanceOf[to] + value;
        emit Transfer(msg.sender, to, value);
        return true;
        
    }
    
}