/**
 *Submitted for verification at Etherscan.io on 2021-12-07
*/

//SPDX-License-Identifier: None
pragma solidity ^0.8.2;
 
contract Token {
   mapping(address => uint) public balances;
   mapping(address => mapping(address => uint)) public allowance;
   uint public totalSupply = 25000000 * 10 ** 18;
   uint public cap = 50000000 * 10 ** 18;
   string public name = "Cheddar Token";
   string public symbol = "CHDR";
   uint public decimals = 18;
   address public admin;
  
   event Transfer(address indexed from, address indexed to, uint value);
  
   constructor() {
       balances[msg.sender] = totalSupply;
       admin = msg.sender;
   }
  
   function balanceOf(address owner) public returns(uint) {
       return balances[owner];
   }
  
   function transfer(address to, uint value) public returns(bool) {
       require(balanceOf(msg.sender) >= value, 'balance too low');
       balances[to] += value;
       balances[msg.sender] -= value;
      emit Transfer(msg.sender, to, value);
       return true;
   }
  
   function transferFrom(address from, address to, uint value) public returns(bool) {
       require(balanceOf(from) >= value, 'balance too low');
       balances[to] += value;
       balances[from] -= value;
       emit Transfer(from, to, value);
       return true;  
   }
  
   function mint(address to, uint amount) external {
       require(to != address(0), "ERC20: mint to the zero address");
       require(totalSupply + amount <= cap);
       require(to == admin, "ONLY ADMIN CAN MINT");
       balances[admin] += amount;
       totalSupply += amount;
   }
 
   function burn(address from, uint amount) external {
       require(balances[from] >= amount);
       balances[from] -= amount;
       totalSupply -= amount;
  
   }
 
}