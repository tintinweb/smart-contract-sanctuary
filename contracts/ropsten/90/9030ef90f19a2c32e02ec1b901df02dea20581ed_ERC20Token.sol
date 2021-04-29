/**
 *Submitted for verification at Etherscan.io on 2021-04-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract ERC20Token {

    string public constant name = "ERC20AVI";
    string public constant symbol = "AVI";
    uint8 public constant decimals = 10;  


    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);


    mapping(address => uint256) balances;

    mapping(address => mapping (address => uint256)) allowed;
    
    uint256 totalSupply_;

    using SafeMath for uint256;


   constructor(uint256 total) public {  
	totalSupply_ = total;
	balances[msg.sender] = totalSupply_;
    }  

    function totalSupply() public view returns (uint256) {
	return totalSupply_;
    }
    
    function balanceOf(address _address) public view returns (uint) {
        return balances[_address];
    }

    function transfer(address receiver, uint numTokens) public returns (bool) {
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }

    function approve(address receiver, uint numTokens) public returns (bool) {
        allowed[msg.sender][receiver] = numTokens;
        emit Approval(msg.sender, receiver, numTokens);
        return true;
    }

    function allowance(address from, address receiver) public view returns (uint) {
        return allowed[from][receiver];
    }

    function transferFrom(address from, address receiver, uint numTokens) public returns (bool) {
        require(numTokens <= balances[from]);    
        require(numTokens <= allowed[from][msg.sender]);
    
        balances[from] = balances[from].sub(numTokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
        emit Transfer(from, receiver, numTokens);
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
      return c;
    }
}