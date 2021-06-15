/**
 *Submitted for verification at Etherscan.io on 2021-06-15
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.5;

contract Token {
    string public name = "First B Token";
    string public symbol = "FBT";

    uint256 public totalSupply = 1000000;

    address public owner;

    mapping(address => uint256) balances;

    event Transfer(address to, uint amount);

    constructor() {
        balances[msg.sender] = totalSupply;
        owner = msg.sender;
    }

    function transfer(address to, uint256 amount) external {
        require(balances[msg.sender] >= amount, "Not enough tokens");

        balances[msg.sender] -= amount;
        balances[to] += amount;
        emit Transfer(to, amount);
    }

    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }
}