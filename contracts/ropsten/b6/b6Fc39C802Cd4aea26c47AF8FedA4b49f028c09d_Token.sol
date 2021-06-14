/**
 *Submitted for verification at Etherscan.io on 2021-06-14
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

contract Token {
    string public name = "Anna Rainbow Token";
    string public symbol = "ART";
    uint public totalSupply = 1000000;
    mapping(address => uint) balances;

    constructor(){
        balances[msg.sender] = totalSupply;
    }

    function transfer(address to, uint amount) external{
        require(balances[msg.sender] >= amount, "Not enough tokens");
        balances[msg.sender] -= amount;
        balances[to] += amount;
    }

    function balanceOf(address account) external view returns (uint){
        return balances[account];
    }
}