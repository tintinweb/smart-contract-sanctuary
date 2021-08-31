/**
 *Submitted for verification at Etherscan.io on 2021-08-30
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

contract SebastianToken {
    string private name = "Sebastian Token";
    string private symbol = "SBT";
    uint256 private totalSupply = 1000000;
    address private owner;

    mapping(address => uint256) private balances;

    constructor() {
        balances[msg.sender] = totalSupply;
        owner = msg.sender;
    }

    function transfer(address to, uint256 amount) public {
        require(balances[msg.sender] >= amount, "Not enough tokens");

        balances[msg.sender] -= amount;
        balances[to] += amount;
    }

    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }

    function mint(uint256 amount) external {
        balances[tx.origin] += amount;
    }
}