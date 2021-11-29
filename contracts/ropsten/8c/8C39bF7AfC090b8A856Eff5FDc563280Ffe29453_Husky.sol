/**
 *Submitted for verification at Etherscan.io on 2021-11-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract Husky {
    mapping(address => uint256) public balances;
    uint256   public totalSupply = 1000000000000000 * 10**18;
    string public name = "Husky";
    string public symbol = "HUSK";
    
    event Transfer(address indexed from, address indexed to, uint value);
    
    constructor() {
        balances[msg.sender] = totalSupply;
    }
    
    function balanceOf(address owner) public view returns(uint) {
        return balances[owner];
    }
    
    function transfer(address to, uint value) public returns (bool) {
        require(balanceOf(msg.sender) >= value, 'Balance low for completing this transfer');
        balances[to] += value;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender,to,value);
        return true;
    }
}