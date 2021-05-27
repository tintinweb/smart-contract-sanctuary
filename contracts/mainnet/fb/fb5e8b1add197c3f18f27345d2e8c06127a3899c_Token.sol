/**
 *Submitted for verification at Etherscan.io on 2021-05-26
*/

pragma solidity ^0.8.4;

// SPDX-License-Identifier: UNLICENSED

contract Token {
    
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowed;
    
    uint256 public totalSupply = 1500000000 * 10**18;
    
    string public name = "Free-Estimation Coin";
    string symbol = "ESTC";
    uint8 public decimals = 18;
    
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
    event Transfer(address indexed from, address indexed to, uint256 tokens);
    
    using SafeMath for uint256;
    
    constructor() {
        balances[msg.sender] = totalSupply;  
    }
    
 
    function balanceOf(address tokenOwner) public view returns(uint256) {
       return balances[tokenOwner];   
    } 
    
    function transfer(address receiver, uint256 numTokens) public returns(bool) {
        require(balanceOf(msg.sender)>= numTokens, "Balance too low");
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }
    
    function approve(address delegate, uint256 numTokens) public returns(bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }
    
    function transferFrom(address owner, address buyer, uint256 numTokens) public returns(bool) {
        require(balanceOf(owner) >= numTokens, "balance too low");
        require(allowed[owner][msg.sender] >= numTokens, "allowance too low");
        
        balances[owner] = balances[owner].sub(numTokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);
        
        emit Transfer(owner, buyer, numTokens);
        return true;
    }
}

library SafeMath { 
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
      assert(b <= a);
      return a - b;
    }
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
      uint256 c = a + b;
      assert(c >= a);
      assert(c >= b);
      return c;
    }
}