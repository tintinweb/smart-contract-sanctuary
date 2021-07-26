/**
 *Submitted for verification at Etherscan.io on 2021-07-26
*/

// SPDX-License-Identifier: MIT
  pragma solidity ^0.8.2;
  
  contract RoyaltyCoin {
      string name;
      
      uint totalSupply;
      
      string  symbol;
      
      uint  decimals;
      
      address owner;
      
      mapping(address => mapping(address => uint)) public delegations;
      
      mapping(address => uint) public balances;
      
      event Transfer(address indexed from, address indexed to, uint amount);
      
      constructor(){
          totalSupply = 10000 * 10 ** 18;
          owner = msg.sender;
          balances[owner] = totalSupply;
          name = "Royalty Token";
          symbol = "RYC";
          decimals = 18;
      }
      
      function balanceOf(address addr) public view returns(uint){
          return balances[addr];
      }
      
      function transfer(address to, uint value) public returns(bool success){
          require(balanceOf(msg.sender) >= value, "Insufficient funds");
          balances[msg.sender] -= value;
          balances[to] += value;
          emit Transfer(owner, to, value);
          return true;
      }
      
      function transferFrom(address from, address to, uint value) public returns(bool success){
          require(from != to, "You cannot transfer to same address");
          require(balanceOf(from) >= value, "Insufficient funds");
          require(delegations[from][msg.sender] >= value, "You are not allowed to spend this amount");
          balances[from] -= value;
          balances[to] += value;
          emit Transfer(from, to, value);
          return true;
      }
      
      function approve(address spender, uint amount) public returns(bool success){
          require(msg.sender != spender, "You cannot approve your own address");
          delegations[msg.sender][spender] = amount;
          return true;
      }
  }