/**
 *Submitted for verification at BscScan.com on 2021-11-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;



contract Bro {
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
   //defining total supply
    uint public totalSupply = 100000000 * 10 ** 18;
    // defining name of my coin
    string public name = "Brotherhood";
    //defining my ticker symbol
    string public symbol = "BRO";
    // defining my decimals
    uint public decimals = 18;
    
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    constructor() {
        //send all coins to address that deploys the contract
        balances[msg.sender] = totalSupply;
        
    }
    //function to read balance of any address
    function balanceOf(address owner) public view returns(uint) {
        return balances[owner];
        
    }
    //function to transfer from 1 address to another
    function transfer(address to, uint value) public returns(bool) {
        //check if sender has balance in wallet. if balance being sent is not more than or equal to transfer amount. display message
        require(balanceOf(msg.sender) >= value, 'Balance too low');
        //add transfer amount to receivers address
        balances[to] += value;
        //remove transfer amount from senders address
        balances[msg.sender] -= value;
        //record event and return value based on success or failure.
        emit Transfer(msg.sender, to, value);
        return true;
        
    }
    //function to send delegated transfers
    function transferFrom(address from, address to, uint value) public returns(bool){
        require(balanceOf(from) >= value, 'Balance too low');
        require(allowance[from][msg.sender] >= value, 'Allowance too low');
        balances[to] += value;
        balances[from] -= value;
        emit Transfer(from, to, value);
        return true;
        
    }
    //approve delegated transfers
    function approve(address spender, uint value) public returns(bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
        
    }
}