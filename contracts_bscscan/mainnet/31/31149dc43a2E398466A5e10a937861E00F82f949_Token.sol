/**
 *Submitted for verification at BscScan.com on 2021-09-21
*/

pragma solidity ^0.8.7;
 
 contract Token {
     mapping(address => uint) public balances;
     mapping(address=> mapping(address => uint)) public allowance;
     uint public totalSupply = 7000000000 * 10 ** 18;
     string public name = "Jonny Token"; 
     string public symbol = "JT";
     uint public decimals = 18;
     
     event Transfer(address indexed from, address indexed to, uint value);
     event Approval(address indexed owner, address indexed spender, uint value);
     
     constructor(){
         balances[msg.sender] = totalSupply;
     }
     
     function balanceOf(address owner) public view returns(uint) {
         return balances[owner];
     }
     
     function transfer(address to, uint value) public returns(bool){
         require(balanceOf(msg.sender)>=value, 'Balnce too low');
         balances[to] += value;
         balances[msg.sender] -= value;
         emit Transfer(msg.sender, to, value);
         return true;
     }
     
     function transferFrom(address from, address to, uint value) public returns(bool){
         require(balanceOf(from) >= value, 'Balnce too low');
         require (allowance[from][msg.sender] >= value, 'Allowance too low');
         balances[to] += value;
         balances[from] -= value;
         emit Transfer(from, to, value);
         return true; 
     }
     
     function approve(address spender, uint value) public returns(bool){
         allowance[msg.sender][spender] = value;
         emit Approval(msg.sender, spender, value);
         return true;
     }
     
 }