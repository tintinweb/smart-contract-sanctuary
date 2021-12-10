/**
 *Submitted for verification at Etherscan.io on 2021-12-10
*/

pragma solidity ^0.8.10;

contract Token {
  string public name = "Tabit Ethereum Token";
  string public symbol = "TBT";
  address public owner;
  uint public totalSupply = 1000000;
  mapping(address => uint) balances;

  constructor() {
    owner = msg.sender;
    balances[msg.sender] = totalSupply;
  }

  function transfer(address to, uint amount) external {
    require(balances[msg.sender] >= amount, 'Not enough tokens');
    // Deduct from sender, Add to receiver 
    balances[msg.sender] -= amount;
    balances[to] += amount;
  }

  function balanceOf(address account) external view returns (uint) {
    return balances[account];
  }
}