/**
 *Submitted for verification at BscScan.com on 2021-07-24
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;
/**
Contract hand crafted with love By www.altnotify.com a crypto trading app
Comments: A very simple contract with 0 taxes on trades
BEWARE OF COPY CONTRACTS: visit our telegram group https://t.me/altnotifyapp or visit our website to confirm you have the right contract.
*/
contract AltCoin {
string public name = "AltNotify";
string public symbol = "Alt";
uint256 public totalSupply = 1000000000000000000000000; // 1 million tokens
uint8 public decimals = 18;
event Transfer(address indexed _from, address indexed _to, uint256 _value);
event Approval(
address indexed _owner,
address indexed _spender,
uint256 _value
);
mapping(address => uint256) public balanceOf;
mapping(address => mapping(address => uint256)) public allowance;
constructor() {
balanceOf[msg.sender] = totalSupply;
}
function transfer(address _to, uint256 _value)
public
returns (bool success)
{
require(balanceOf[msg.sender] >= _value);
balanceOf[msg.sender] -= _value;
balanceOf[_to] += _value;
emit Transfer(msg.sender, _to, _value);
return true;
}
}