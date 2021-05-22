/**
 *Submitted for verification at Etherscan.io on 2021-05-21
*/

pragma solidity ^0.8.3;

contract Bl4ckToken{
    string public name = "Santiago Sarabia's Token V0.1";
    string public symbol = "SS01";
    uint public totalSupply = 10000000;
    mapping(address => uint) public balances;
    
    constructor() {
        balances[msg.sender] = totalSupply;
    }

    function transfer(address to, uint amount) external {
        require(balances[msg.sender] >= amount, "Not enough tokens");
        balances[msg.sender] -= amount;
        balances[to] += amount;
    }

    function balanceOf(address account) external view returns (uint) {
        return balances[account];
    }
}