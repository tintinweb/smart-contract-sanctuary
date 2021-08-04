/**
 *Submitted for verification at Etherscan.io on 2021-08-04
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

contract ChainShot {
    string public name = "ChainShot";
    string public symbol = "CS";

    uint256 public totalSupply = 100000;

    address public owner;

    mapping(address => uint256) balances;

    constructor() {

        balances[msg.sender] = totalSupply;
        owner = msg.sender;
    }

    function transfer(address to, uint256 amount) external {
        require(balances[msg.sender] >= amount, "Not enough tokens");

        // Transfer the amount.
        balances[msg.sender] -= amount;
        balances[to] += amount;
    }

    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }
}