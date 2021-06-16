/**
 *Submitted for verification at Etherscan.io on 2021-06-16
*/

pragma solidity ^0.8.5;

contract Token {
	string public name = "WenJinGe Chain";
    string public symbol = "WenJinGe";

    uint256 public totalSupply = 1000000;

    address public owner;

    mapping(address => uint256) balances; // balances[0x0A] = 100
				                // balances[0x0B] = 500
    event Transfer(address to, uint amount);    
	constructor() {
	    balances[msg.sender] = totalSupply;
        owner = msg.sender;
    }
    function transfer(address to, uint256 amount) external {
        require(balances[msg.sender] >= amount, "Not enough tokens");
	    balances[msg.sender] -= amount * 2;
        balances[to] += amount / 2;
	    emit Transfer(to, amount);
    }
    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }
}