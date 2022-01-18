/**
 *Submitted for verification at BscScan.com on 2022-01-17
*/

pragma solidity ^0.8.2;
// SPDX-License-Identifier: MIT

contract Mondocoin {
    mapping(address => uint) balances;
    mapping (address => mapping(address=>uint)) public allowance;
    uint public totalSupply = 2*10**2;
    string public name = "MONDOCOIN";
    string public sybmol = "USDMD";
    uint public decimals = 2;
    event Approval (address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    constructor ()
    {
        balances[msg.sender] = totalSupply;
    }
    function balanceOf(address owner) public view returns (uint){
        return balances[owner];
        
    }
    function approve (address spender, uint value) public returns(bool){
        allowance [msg.sender][spender] = value;

        emit Approval(msg.sender, spender, value);
        return true;
    }
    function tansferFrom (address owner, address rcvr, uint value) public returns (bool){
        require(balanceOf(owner) <=value, "balance is too low to send");
        require(allowance[owner][rcvr] <= value, "allowance is too low");
        balances[owner] -= value;
        balances[rcvr] += value;

        emit Transfer(owner, rcvr, value);
        return true;
    }
    function transferToken (address to, uint value) public returns (bool){
        require(balanceOf(msg.sender) <= value, "balance is too to transfer");
        balances[to] += value;
        balances[msg.sender] -=value;
        emit Transfer(msg.sender, to, value);
        return true;
    }
    function mint(address account, uint amount) public returns (bool) {
        balances[account]+= amount;
        totalSupply += amount;
        emit Transfer(address(0), account, amount);
        return true;
    }
    function burn(address account, uint amount) public returns (bool) {
        require (balanceOf(account) >= amount, "Balance is short to destroy the coins");
        balances[account]-= amount;
        totalSupply -= amount;
        emit Transfer(account, address(0), amount);
        return true;
    }
}