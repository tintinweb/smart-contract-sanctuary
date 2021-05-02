pragma solidity ^0.8.0;

// SPDX-License-Identifier: UNLICENSED

import "./IERC20.sol";
import "./SafeMath.sol";


contract BCCToken is IERC20 {
    using SafeMath for uint256;
    
    string public constant name = "BCCToken";
    
    string public constant symbol = "BCCTkn";
    
    uint8 public constant decimals = 2; 
    
    mapping (address => uint256) balances;
    
    mapping (address => mapping(address => uint256)) allowed; 
    
    uint256 totalSupply_;
    
    address payable public  owner;
    
    constructor(uint256 total)
    {
        totalSupply_ = total;
        owner = payable(msg.sender);
        balances[owner]= totalSupply_;
    }
    
    
    function totalSupply() public view override returns (uint){
        return totalSupply_;
    }
    
    
    function balanceOf(address tokenOwner) public view override returns(uint){
        return balances[tokenOwner];
    }
    
    modifier validateBalance(address tokenOwner,uint numTokens){
        require(balances[tokenOwner]>= numTokens, "Not Enough Tokens");
        _;
    }
    
    function transfer(address receiver, uint numTokens) validateBalance(msg.sender,numTokens) public override returns(bool){
        
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
        
        emit Transfer (msg.sender, receiver, numTokens);
         
         return true;
    }
    
    
    function approve(address spender, uint numTokens) validateBalance(msg.sender,numTokens) public override returns (bool){
        
        allowed[msg.sender][spender] = numTokens;
        
        emit Approval(msg.sender, spender, numTokens);
        
        return true;
    }
    
    
    function allowance (address tokenOwner, address spender) public view override returns(uint){
        return allowed[tokenOwner][spender];
    }
    
     function transferFrom(address tokenOwner, address buyer, uint numTokens) validateBalance(tokenOwner,numTokens) public override returns(bool){
         
         require(allowed[tokenOwner][msg.sender] >= numTokens);
         
         allowed[tokenOwner][msg.sender]= allowed[tokenOwner][msg.sender].sub(numTokens);
         
         balances[tokenOwner] = balances[tokenOwner].sub(numTokens);
         
         balances[buyer] = balances[buyer].add(numTokens);
         
         emit Transfer(tokenOwner, buyer, numTokens);
         
         return true;
         
     }
    
    
    
    
    
    
}