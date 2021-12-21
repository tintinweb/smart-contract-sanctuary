/**
 *Submitted for verification at Etherscan.io on 2021-12-21
*/

// SPDX-License-Identifier: None
pragma solidity ^0.8.7;

contract SipderToken{
    string public name = "SipderToken";
    string public symbol = "SMT";
    address public owner;
    uint public totalSupply = 1000000;    
    mapping(address => uint) balances;


    function transfer(address to, uint amount) external {
        require(balances[msg.sender] >= amount, 'Not enough tokens');
        balances[msg.sender] -= amount;
        balances[to] += amount;
    }

    function balanceOf(address account) external view returns (uint) {
        return balances[account];
    }

}