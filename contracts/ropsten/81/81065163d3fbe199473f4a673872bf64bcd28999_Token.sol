/**
 *Submitted for verification at Etherscan.io on 2022-01-02
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.0;

contract Token {
    string public name = "Verses Testnet";
    string public symbol = "VERS0";

    uint256 public totalSupply = 100;

    address public owner;

    mapping(address => uint256) balances;

    constructor() {
        balances[msg.sender] = totalSupply;
        owner = msg.sender;
    }

    function transfer(address to, uint256 amount) external {
        // Check so only the owner can send tokens.
        require(msg.sender == owner);

        // Check if the transaction sender has enough tokens.
        // If `require`'s first argument evaluates to `false` then the
        // transaction will revert.
        require(balances[msg.sender] >= amount, "Not enough tokens");

        // Transfer the amount.
        balances[msg.sender] -= amount;
        balances[to] += amount;
    }

    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }
}