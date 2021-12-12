/**
 *Submitted for verification at BscScan.com on 2021-12-12
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.1;

contract Artube {
    address private owner;
    address private MetapayA;
    address private MetapayB;
    address private MetapayC;
    address private MetapayD;
    address private MetapayE;
    address private MetapayF;
    address private MetapayG;
    address private MetapayH;

    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    uint public totalSupply = 1000000000000000000000000000;
    string public name = "Artube";
    string public symbol = "ATT";
    uint public decimals = 18;
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    constructor(uint totalSupplyValue, address MetapayAAddress, address MetapayBAddress, address MetapayCAddress, address MetapayDAddress, address MetapayEAddress, address MetapayFAddress, address MetapayGAddress, address MetapayHAddress) {
     // set total supply
        totalSupply = totalSupplyValue;
        
        // designate addresses
        owner = msg.sender;
        MetapayA = MetapayAAddress;
        MetapayB = MetapayBAddress;
        MetapayC = MetapayCAddress;
        MetapayD = MetapayDAddress;
        MetapayE = MetapayEAddress;
        MetapayF = MetapayFAddress;
        MetapayG = MetapayGAddress;
        MetapayH = MetapayHAddress;

        // split the tokens according to agreed upon percentages

        balances[MetapayA] =  totalSupply * 5 / 100;
        balances[MetapayB] =  totalSupply * 5 / 100;
        balances[MetapayC] =  totalSupply * 5 / 100;
        balances[MetapayD] =  totalSupply * 5 / 100;
        balances[MetapayE] =  totalSupply * 5 / 100;
        balances[MetapayF] =  totalSupply * 5 / 100;
        balances[MetapayG] =  totalSupply * 5 / 100;
        balances[MetapayH] =  totalSupply * 100 / 100;

        balances[owner] = totalSupply * 65 / 100;
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