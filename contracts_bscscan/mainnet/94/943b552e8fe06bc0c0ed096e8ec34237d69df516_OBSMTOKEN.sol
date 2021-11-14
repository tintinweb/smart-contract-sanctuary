/**
 *Submitted for verification at BscScan.com on 2021-11-14
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.2;

contract OBSMTOKEN {
    
    
    string public constant name = 'OBSM TOKEN';
    string public constant symbol = 'OBSM';
    uint8 public constant decimals = 18;
    
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenowner, address indexed spender, uint tokens);
    
    uint256 totalSupply_;
    
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    
    constructor() {
        totalSupply_ = 1000000000000 * 10 ** decimals;
        balances[msg.sender] = totalSupply_;
    }
        
 function totalSupply() public view returns (uint256) {
     return totalSupply_;
 } 
 
 function balanceOf(address tokenOwner) public view returns (uint) {
     return balances[tokenOwner];
 }
  
  function transfer(address receiver, uint numTokens) public returns(bool) {
      require(numTokens <= balances[msg.sender]);
      balances[msg.sender] = balances[msg.sender] -numTokens;
      balances[receiver] = balances[receiver] + numTokens;
      emit Transfer(msg.sender, receiver, numTokens);
      return true;
  }

    function approve(address delegate, uint numTokens) public returns (bool) {
      allowed[msg.sender][delegate] = numTokens;
      emit Approval(msg.sender, delegate, numTokens);
      return true;
  } 
   
   function allowance(address owner, address delegate) public view returns (uint) {
       return allowed[owner][delegate];
       
   } 
   
   function transferFrom(address owner, address buyer, uint numTokens) public returns (bool) {
       require(numTokens <= balances[owner]);
       require(numTokens <= allowed[owner][msg.sender]);
       balances[owner] = balances[owner] - numTokens;
       allowed[owner][msg.sender] = allowed[owner][msg.sender] - numTokens;
       balances[buyer] = balances[buyer] + numTokens;
       emit Transfer(owner, buyer, numTokens);
       return true;
   }
}