/**
 *Submitted for verification at Etherscan.io on 2021-09-30
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;


// ----------------------------------------------------------------------------
// Safe Math Library
// ----------------------------------------------------------------------------
contract SafeMath {
    
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a); 
        c = a - b; 
        
    } 
        
    function safeMul(uint a, uint b) public pure returns (uint c) {
            c = a * b; 
            require(a == 0 || c / a == b); 
            
    } 
        
    function safeDiv(uint a, uint b) public pure returns (uint c) {
            require(b > 0); 
            c = a / b; 
            
    }
}

// Contract for token

contract MiToken is SafeMath  {
    string public name;
    string public symbol;
    // uint public decimal; // 18 decimals is the strongly suggested default, avoid changing it
    uint public total_supply;
    
    mapping(address => uint) balances;
    mapping(address => mapping(address=>uint)) allowed;
    
     /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
     
     constructor()  {
         
         name = 'MiToken';
         symbol = 'mi';
        //  decimal = 18;
         total_supply = 100000000;
         
         balances[msg.sender] = total_supply;
         emit Transfer(address(0), msg.sender, total_supply);
         
     }
     
     // Declare two events 
     //1-> Transfer
     //2-> Approval
     
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
     
     
    // Make six function
    
    //1-> totalSupply()
    //2-> balanceOf
    //3-> allowance
    //4-> transfer
    //5-> approve
    //6-> transferFrom
    
    function totalSupply() public view returns(uint){
        return total_supply - balances[address(0)];
        
    }
    
    function balanceOf(address tokenOwner) public view returns(uint balance){
        return balances[tokenOwner];
        
    }
    
    function allowance(address tokenOwner, address spender) public view returns(uint remaining){
        return allowed[tokenOwner][spender];
        
    }
    
    function approve(address spender,uint tokens) public returns(bool success){
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender,spender,tokens);
        return true;
        
    }
    
    function transfer(address to, uint tokens) public returns(bool success){
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to],tokens);
        emit Transfer(msg.sender,to,tokens);
        
        return true;
        
    }
    
    function transferFrom(address from,address to, uint tokens) public returns(bool success){
        balances[from] = safeSub(balances[from],tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender],tokens);
        balances[to] = safeAdd(balances[to],tokens);
        emit Transfer(from,to,tokens);
        return true;
        
    }
    
    
    
}