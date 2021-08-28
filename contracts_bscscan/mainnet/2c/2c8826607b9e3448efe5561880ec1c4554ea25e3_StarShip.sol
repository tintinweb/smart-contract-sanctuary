/**
 *Submitted for verification at BscScan.com on 2021-08-28
*/

// SPDX-License-Identifier: UNLISCENSED

pragma solidity 0.8.4;

 
contract StarShip {
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    string public name = "StarShip";
    string public symbol = "STARS";
    uint public totalSupply = 1000000000000000000000000; // 1 million tokens
    uint public decimals = 18;
    
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
    
    function transferFrom(address from, address to, uint value) public returns (bool) {
        require(balanceOf(from) >= value, 'balance too low');
        require(allowance[from][msg.sender] >= value, 'allowance too low');
        balances[to] += value;
        balances[from] -= value;
        emit Transfer(from, to, value);
        return true;
    }
    
     function Approve(address spender, uint value) public returns(bool) {
         allowance[msg.sender][spender] = value;
         emit Approval(msg.sender, spender, value);
         return true;
     }
}