/**
 *Submitted for verification at Etherscan.io on 2021-06-27
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;

contract PranayBathiniToken {

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalSupply ;
    
    // Optional params
    string public name;                 
    uint8 public decimals;                
    string public symbol;                
    string public version = 'V.1.0';   
    
    constructor() {
        balances[msg.sender] = 21000000;               
        name = "Pranay Bathini Token";     
        totalSupply = 21000000;
        decimals = 0;                           
        symbol = "PBT";                             
    }

    function balanceOf(address _owner) public view  returns (uint256 balance) {
        return balances[_owner];
    }
    
    function transfer(address _to, uint256 _value) public  returns (bool success) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            emit Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

}