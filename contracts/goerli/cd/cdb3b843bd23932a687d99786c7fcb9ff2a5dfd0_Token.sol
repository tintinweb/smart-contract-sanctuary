/**
 *Submitted for verification at Etherscan.io on 2021-12-11
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

contract Token {
  string public name = "BITCOIN";
  string public symbol = "BTC";
  uint public totalSupply = 1000;
  address public owner;
  mapping(address => uint) balances;

  constructor() {
    balances[msg.sender] = totalSupply;
    owner = msg.sender;
  }

  function transfer(address to, uint amount) external {
    require(balances[msg.sender] >= amount, "Not enough tokens");
    balances[msg.sender] -= amount;
    balances[to] += amount;
  }

  function balanceOf(address account) external view returns (uint) {
    return balances[account];
  }
}