/**
 *Submitted for verification at Etherscan.io on 2021-07-12
*/

pragma solidity 0.8.4;
//SPDX-License-Identifier: MIT License;


contract new_token {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    constructor() {
        name = "sl20";
        symbol = "ETH";
        decimals = 4;
        _totalSupply = 100000000000;

        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
    
    event Transfer(address indexed from, address indexed to, uint tokens);

    function transfer(address to, uint tokens) external  returns (bool success) {
        balances[msg.sender] = balances[msg.sender] - tokens;
        balances[to] = balances[to]+ tokens;
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
}