/**
 *Submitted for verification at Etherscan.io on 2021-03-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a); c = a - b; 
        
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

contract IaunToken is SafeMath {
    
    uint public constant _totalSupply = 1000000000000;
    uint public constant decimals = 8;
    string public constant name = "IaunToken";
    string public constant symbol = "IT";
    
    mapping(address => uint256) balances;
    
    mapping(address => mapping(address => uint256)) allowed;
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
    constructor(){
        balances[msg.sender] = _totalSupply;
        
    }
    
    
    function totalSupply() public pure returns (uint256){
        return _totalSupply;
    }
    
    function balanceOf(address account) public view returns (uint256){
        return balances[account];
    }
    
    function transfer(address recipient, uint256 amount) public returns (bool){
        require(
            balances[msg.sender] >= amount &&
            amount > 0
        );
        balances[msg.sender] = safeSub(balances[msg.sender],amount);
        balances[recipient] = safeAdd(balances[recipient],amount);
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }
    
    function allowance(address _owner, address spender) public view returns (uint256){
        return allowed[_owner][spender];
    }
    
    function approve(address spender, uint256 amount) public returns (bool){
        require(
            amount > 0 &&
            balances[msg.sender] >= amount
        );
        allowed[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool){
        require(
            allowed[sender][msg.sender] >= amount &&
            amount > 0 && 
            balances[sender] >= amount
        );
        balances[sender] = safeSub(balances[sender], amount);
        balances[recipient] = safeAdd(balances[recipient],amount);
        allowed[sender][msg.sender] = safeSub(allowed[sender][msg.sender],amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

}