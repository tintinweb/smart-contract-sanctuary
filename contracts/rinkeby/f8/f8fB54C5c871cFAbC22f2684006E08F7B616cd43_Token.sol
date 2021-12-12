/**
 *Submitted for verification at Etherscan.io on 2021-12-11
*/

pragma solidity ^0.8.7;

contract Token {
    string public name = "J Token";
    string public symbol = "JRP";
    address public owner;
    uint256 public totalSupply = 1000001;
    mapping(address => uint256) balances;

    constructor() {
        owner = msg.sender;
        balances[msg.sender] = totalSupply;
    }

    function transfer(address to, uint256 amount) external {
        require(balances[msg.sender] >= amount, "Not enough tokens");
        // Deduct from sender, Add to receiver
        balances[msg.sender] -= amount;
        balances[to] += amount;
    }

    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }
}