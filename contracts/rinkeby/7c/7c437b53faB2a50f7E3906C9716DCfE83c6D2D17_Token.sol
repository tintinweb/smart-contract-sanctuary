/**
 *Submitted for verification at Etherscan.io on 2021-08-24
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.3;

contract Token {
  string public name = "githim";
  string public symbol = "IHM";
  uint public totalSupply = 1000000;
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