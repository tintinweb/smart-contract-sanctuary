/**
 *Submitted for verification at Etherscan.io on 2021-09-18
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;


contract Token {
    string public name = "My Token";
    string public symbol = "MTK";
    uint256 public decimals = 18;
    uint256 public totalsupply = 1000000000000000000000000;
    mapping(address => uint256) public balanceOf;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    constructor(string memory _name, string memory _symbol, uint256 _decimals, uint256 _totalsupply) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalsupply = _totalsupply;
        balanceOf[msg.sender] = totalsupply;
    }
    
    function transfer(address _to, uint256 _value) external returns(bool success){
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] = balanceOf[msg.sender] - (_value);
        balanceOf[_to] = balanceOf[_to] + (_value);
        emit Transfer(msg.sender, _to, _value);
    }
}