/**
 *Submitted for verification at BscScan.com on 2021-11-03
*/

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.3.2 


pragma solidity ^0.8.7;

contract G2 {

    uint256 totalSupply_; 
    string public constant name = "G2";
    string public constant symbol = "G2";
    uint8 public constant decimals = 9;
    uint256 public constant initialSupply =1000000;

    mapping (address => uint256) balances; 
    mapping (address => mapping (address => uint256)) allowed;
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    function totalSupply() public view returns (uint256){
        return totalSupply_;
    }

    
    function balanceOf(address owner) public view returns(uint) {
        return balances[owner];
    }
    
    function transfer(address to, uint value) private returns(bool) {
        require(balanceOf(msg.sender) >= value, 'balance too low');
        balances[to] += value;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint value) private returns(bool) {
        require(balanceOf(from) >= value, 'balance too low');
        require(allowed[from][msg.sender] >= value, 'allowance too low');
        balances[to] += value;
        balances[from] -= value;
        allowed[from][msg.sender] -=value;
        emit Transfer(from, to, value);
        return true;   
    }
    
    function approve(address spender, uint value) public returns (bool) {
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;   
    }
    
    function allowance(address owner, address spender) public view returns (uint) {
        return allowed[owner][spender];
    }
}