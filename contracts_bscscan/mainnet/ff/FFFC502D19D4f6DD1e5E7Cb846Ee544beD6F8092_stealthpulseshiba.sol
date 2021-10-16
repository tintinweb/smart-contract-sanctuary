/**
 *Submitted for verification at BscScan.com on 2021-10-16
*/

/*

Stealth Pulse Shiba with no telegram features.
Contract is the same as the original pulseshiba.
Liquidity will be locked for a week in mudra.
Initial liquidity will be 1 bnb.
99% of total supply will be sent to the liquidity, I'll keep the 1% for my fees kek.
For everyone that's reading this, make a group called @stealthpulseshiba or something if you want.
Shill it hard if you want it to moon, with $400 initial market cap, whichever buy first will have a lot of x's.

*/

pragma solidity ^0.8.2;

contract stealthpulseshiba {
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    uint public totalSupply = 100000 * 10 ** 18;
    string public name = "stealthpulseshiba";
    string public symbol = "stealthpulseshiba";
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