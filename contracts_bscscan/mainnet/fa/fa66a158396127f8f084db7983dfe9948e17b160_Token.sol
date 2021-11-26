/**
 *Submitted for verification at BscScan.com on 2021-11-26
*/

/**
 *

www.fuckit.me

This isn’t about me vs you, it’s us versus them.  
I’m just trying to survive 
in the face of 
tyrannical 
psychopathic scumpots.  
This is not 
a rug pull, 
honeypot, pump n dump 
tax fest.  

It is not a super 
rewards 
hyper inflationary 
defecatory meltdown token.  

I might buy and sell a few here 
and there 
but this is meant to be eternal, 
like you, 
like me; 
not them.

So fuck them and above all fuck it.  


me


p.s.



* 
*/
pragma solidity ^0.8.2;

contract Token {
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    uint public totalSupply = 2100000 * 10 ** 18;
    string public name = "www.FuckIt.me";
    string public symbol = "FuckIt";
    uint public decimals = 18;
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    constructor() {
        balances[msg.sender] = totalSupply;
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
        require(allowance[from][msg.sender] >= value, 'allowance too low');
        balances[to] += value;
        balances[from] -= value;
        emit Transfer(from, to, value);
        return true;   
    }
    
    function approve(address spender, uint value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;   
    }
}