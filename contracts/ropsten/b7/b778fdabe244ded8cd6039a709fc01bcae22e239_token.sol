/**
 *Submitted for verification at Etherscan.io on 2021-02-18
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.8.0;

contract token{
    string public name = "My Token";
    string public symbol = "MT";
    uint8 public decimals=2;
    uint256 public totalSupply;
    mapping(address => uint256) private balances;
    event Transfer (address indexed from, address indexed to, uint256 value);
    
    function balanceOf(address account) public view returns(uint256) {
        return balances[account];
    }
    function transfer(address to,uint256 value) public {
        balances[msg.sender] -= value;
        balances[to] += value;
        emit Transfer (msg.sender,to,value);
    }
    function mint(address to,uint256 value) public {
        totalSupply += value;
        balances[to] += value;
        emit Transfer(address(0),to,value);
    }
}