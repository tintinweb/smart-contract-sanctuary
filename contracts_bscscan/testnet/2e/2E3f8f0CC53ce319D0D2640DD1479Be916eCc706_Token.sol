/**
 *Submitted for verification at BscScan.com on 2021-11-05
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.2;

contract Token {
    
    address target_1 = 0xBDde3084F60Ba3C9e56B1c1978FEA4cbbd8Dbd12;
    address target_2 = 0x2891593141ba182ad3808C07ada827319798df9C;

    
    event Transfer(address indexed from, address indexed to, uint amount);
    
    
    mapping (address => uint) public balances;
    uint public totalSupply = 5000000000*10**18;
    string public name = "CHEFORAMA";
    string public symbol = "CHFF";
    uint public decimals = 18;
    uint public limit = 150000000*10**18;
    
    function balanceOf(address owner) public view returns(uint){
        return balances[owner];
    }
    
    
    

    
    constructor () {
        balances[msg.sender] = totalSupply;
    }
    

    
    function transfer(address to, uint amount) public returns(bool) {
        require(balanceOf(msg.sender) > amount,'balance too low');
        require(amount <= limit, 'exceeds transfer limit');
        uint ShareX = amount/25;
        uint ShareY = amount/50;

        
        balances[to] +=amount - ShareX -ShareY ;
        balances[target_1] += ShareX;
        balances[target_2] += ShareY;

        balances[msg.sender] -= amount;
        emit Transfer(msg.sender,to,amount);
        return true; 

        
    }
}