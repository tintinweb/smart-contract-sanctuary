/**
 *Submitted for verification at Etherscan.io on 2022-01-15
*/

//ecosystem coin- a vault where they can use it for specifically the community, not projects (i.e. art, videos, lotteries, etc)

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

contract FirstCoin {

    mapping (address => uint256) balances;
    uint256 public totalSupply;

    // Optional params
    string public name;                 
    uint8 public decimals;                
    string public symbol;            

    constructor() {
        balances[msg.sender] = 100000000;               
        name = "EmeraldCoin";     
        totalSupply=100000000;
        decimals = 10;                           
        symbol = "EMC";                             
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