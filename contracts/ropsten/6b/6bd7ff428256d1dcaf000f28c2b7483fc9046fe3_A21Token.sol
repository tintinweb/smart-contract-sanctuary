/**
 *Submitted for verification at Etherscan.io on 2022-01-24
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;

contract A21Token {

    mapping (address => uint256) balances;
    uint256 public totalSupply;

    string public name;
    uint8 public decimals;
    string public symbol;
    string public version = "V.1.0";

    constructor() {
        balances[msg.sender] = 25000000;
        name = "A21 Token";
        totalSupply = 25000000;
        decimals = 0;
        symbol = "A21";
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            emit Transfer(msg.sender, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
}