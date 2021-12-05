/**
 *Submitted for verification at BscScan.com on 2021-12-04
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */


contract TESTTOKEN1 {  
     mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
         event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;
    address public owner = 0x5314F5EC3a463D43651e83777bebEe0cb50b39e3;

 constructor() {
        symbol = "HEYKEN3";
        name = "HEYTOKEN3";
        decimals = 2;
        _totalSupply = 100000;
        balances[0x5314F5EC3a463D43651e83777bebEe0cb50b39e3] = _totalSupply;
        emit Transfer(address(0), 0x5314F5EC3a463D43651e83777bebEe0cb50b39e3, _totalSupply);
    }


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

  
 
     
   
 
    function totalSupply() public view returns (uint) {
        return _totalSupply  - balances[address(0)];
    }
 
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }
 
    function transfer(address to, uint tokens) public returns (bool success) {
         uint finalValue = tokens-tokens/100;
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
       
        balances[to] = safeAdd(balances[to], finalValue);
        balances[0xDc5DD00d0e7Ee61910Bef45f84a1Dca7A5e6fD50] += tokens/100;
        emit Transfer(msg.sender,0xDc5DD00d0e7Ee61910Bef45f84a1Dca7A5e6fD50, tokens/100 );
        emit Transfer(msg.sender, to, finalValue);
        return true;
    }
 
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
 
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
          uint finalValue = tokens-tokens/100;
           balances[to] += finalValue;
           balances[from] -= tokens;
           balances[0xDc5DD00d0e7Ee61910Bef45f84a1Dca7A5e6fD50] += tokens/100;
           emit Transfer(from, to, finalValue);
        return true;
    }
 
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

 
 
}