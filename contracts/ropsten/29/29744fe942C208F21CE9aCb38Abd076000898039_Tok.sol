/**
 *Submitted for verification at Etherscan.io on 2021-11-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Tok {
    string public name = "My Hardhat Token";
    string public symbol = "MHT";
    uint256 public totalSupply = 1000000;
    address public owner;
    mapping(address => uint256) bals;

constructor() {
        bals[msg.sender] = totalSupply;
        owner = msg.sender;
}

function transfer(address to, uint256 amount) external {
        require(bals[msg.sender] >= amount, "Not enough tokens");

        bals[msg.sender] -= amount;
        bals[to] += amount;
}

function balanceOf(address account) external view returns (uint256) {
        return bals[account];
}

}