/**
 *Submitted for verification at BscScan.com on 2021-07-31
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.2;

contract Token {
    
    //mapping the balance allows one to use a series of records
mapping(address => uint) public balances;
    
    // Total Supply and made public so we can view this value on another smart contract usng the api of etheruem
    mapping(address => mapping(address => uint)) public allowance;
    uint public totalSupply = 1000000000000000000000;
    string public name = "AVRA"; 
    string public symbol = "AVRA";
    uint public decimals = 18; //shows the smallest amount of the token that can be transfered

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

    //can be executed only once
    constructor() {
        //we send the TS to the address that deploys the smart contract, always the owner of the token
        balances[msg.sender] = totalSupply;
    }
    
    //to read the balance of any address and made public so it can be called outsde the smart contract and view makes it a read only function
    function balanceOf(address owner) public view returns(uint) {
        return balances[owner];
    }
    
    function transfer(address to, uint value) public returns(bool) {
        //allows you to test a condition
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
    
    function approve(address pender, uint value) public returns(bool) {
        allowance[msg.sender][pender] = value;
        emit Approval(msg.sender, pender, value);
        return true;
    }
}