/**
 *Submitted for verification at Etherscan.io on 2021-06-30
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.6.12;


contract Token {

mapping(address => uint256) balances;
mapping(address => mapping(address => uint256)) public allowance;

uint256 public totalSupply = 1000000000000 * 10 **18;
string public name = "Floki";
string public symbol = "FLK";
uint256 public decimals = 18;

event Transfer(address indexed from, address indexed to, uint256 value);
event Approval(address indexed owner, address indexed spender, uint256 value);
constructor () public {
balances [msg.sender] = totalSupply;
}

function balanceOf(address owner) public view returns(uint256) {
return balances[owner];
}

function transfer(address to, uint256 value) public returns(bool){
require(balanceOf(msg.sender) >= value, 'balance too low');
balances[to] += value;
balances[msg.sender] -= value;
emit Transfer(msg.sender, to, value);
return true;
}

function transferFrom(address from, address to, uint256 value) public returns(bool) {
require(balanceOf(from) >= value, 'balanace toooo low');
require(allowance[from][msg.sender] >= value, 'allowance too low');
balances[to] += value;
emit Transfer(from, to, value);
return true;
}
function approve(address spender, uint256 value) public returns(bool) {
allowance[msg.sender][spender] = value;
emit Approval(msg.sender, spender, value);
return true;
}

}