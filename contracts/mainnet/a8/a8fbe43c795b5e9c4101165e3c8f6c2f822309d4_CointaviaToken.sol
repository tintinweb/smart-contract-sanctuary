/**
 *Submitted for verification at Etherscan.io on 2021-05-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


contract CointaviaToken {
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    uint public totalSupply = 10000 * 10 ** 18;
    string public name = "Cointavia";
    string public symbol = "CONTAVI";
    uint public decimal = 18;
   
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed sender,uint value);
   
    constructor(){
        balances[msg.sender] = totalSupply;
       
    }
   
    function balanceOf(address owner) public view returns(uint){
        return balances[owner];
    }
   
    function transfer(address to, uint value) public returns(bool){
        require(balanceOf(msg.sender) >= value, 'Blanace not there');
        balances[to] += value;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, to ,value);
        return true;
    }
   
    function transferFrom(address from,address to,uint value) public returns(bool){
        require(balanceOf(from) >= value,'balance too low');
        require(allowance[from][msg.sender] >= value, 'allowance too low');
        balances[to] += value;
        balances[from] -= value;
        emit Transfer(from,to, value);
        return true;
       
    }
   
    function approve(address spender, uint value) public returns(bool){
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender,spender,value);
        return true;
    }
}