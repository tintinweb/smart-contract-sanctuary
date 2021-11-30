/**
 *Submitted for verification at BscScan.com on 2021-11-30
*/

/**
 *Tested By TechRate Team at Solidity.io on 2021-10-30
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.6;

contract GODZMONEYMAKER {
    address private owner;
    address private GODZA;
    address private GODZB;
    address private GODZC;
    address private GODZD;
    address private GODZE;
    address private GODZF;
    address private GODZG;
    address private GODZH;

    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    uint public totalSupply = 10000000000000000 * 10 ** 9;
    string public name = "GODZ MONEY MAKER";
    string public symbol = "GODZMOMA";
    uint public decimals = 9;
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    constructor(uint totalSupplyValue, address GODZAAddress, address GODZBAddress, address GODZCAddress, address GODZDAddress, address GODZEAddress, address GODZFAddress, address GODZGAddress, address GODZHAddress) {
     // set total supply
        totalSupply = totalSupplyValue;
        
        // designate addresses
        owner = msg.sender;
        GODZA = GODZAAddress;
        GODZB = GODZBAddress;
        GODZC = GODZCAddress;
        GODZD = GODZDAddress;
        GODZE = GODZEAddress;
        GODZF = GODZFAddress;
        GODZG = GODZGAddress;
        GODZH = GODZHAddress;

        // split the tokens according to agreed upon percentages

        balances[GODZA] =  totalSupply * 5 / 100;
        balances[GODZB] =  totalSupply * 5 / 100;
        balances[GODZC] =  totalSupply * 5 / 100;
        balances[GODZD] =  totalSupply * 5 / 100;
        balances[GODZE] =  totalSupply * 5 / 100;
        balances[GODZF] =  totalSupply * 5 / 100;
        balances[GODZG] =  totalSupply * 5 / 100;
        balances[GODZH] =  totalSupply * 5 / 100;

        balances[owner] = totalSupply * 60 / 100;
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