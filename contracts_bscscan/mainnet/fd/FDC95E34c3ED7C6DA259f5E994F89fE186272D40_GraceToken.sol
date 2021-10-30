/**
 *Submitted for verification at BscScan.com on 2021-10-30
*/

// contracts/Grace.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract GraceToken {
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    
    uint public totalSupply = 299792458 * 10 ** 18;
    string public name = "Grace";
    string public symbol ="GRA";
    uint public decimals = 18;
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    constructor(){
        balances[msg.sender] = 1000000 * 10 ** 18;
    }
    
    function balanceOf(address owner) public view returns(uint){
        return balances[owner];
    }
    
    function transfer(address to, uint value) public returns(bool){
        require(balanceOf(msg.sender) >= value, 'balance to low');
        balances[to] += value;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function TransferFrom(address from, address to, uint value) public returns(bool){
        require(balanceOf(from) >= value, 'balance to low');
        require(allowance[from][msg.sender] >= value, 'allowance to low');
        balances[to] += value;
        balances[from] -= value;
        emit Transfer(from, to, value);
        return true;
    }
    
    function approve(address spender, uint value) public returns(bool){
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
}