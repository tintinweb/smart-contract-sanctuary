/**
 *Submitted for verification at BscScan.com on 2021-07-20
*/

pragma solidity ^0.8.4;


/*
    $PAU, Pau Coin
    
    Total supply: 1000
    100% total supply to the pool.
    No decimals bullshit, just 1000 coins, simple.
    
    This is not a coin to scam or to welcome speculators, it's just the coin of Pau. 
    Monetary speaking it's not worth a shit, but in the future there will be premium services created by Pau that will only accept $PAU or paying a lot in $ETH. 
    So yeah, given the small amount of supply, if there is no more free supply this token can end up worthing a lot indirectly (if using my future services/projects).
    
*/


contract PAU {
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    uint public totalSupply = 1000;
    string public name = "PAU";
    string public symbol = "PAU";
    uint public decimals = 0;
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    constructor() {
        balances[msg.sender] = totalSupply;
    }
    
    function balanceOf(address owner) public view returns(uint) {
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
    
    function approve(address spender, uint value) public returns(bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    
}