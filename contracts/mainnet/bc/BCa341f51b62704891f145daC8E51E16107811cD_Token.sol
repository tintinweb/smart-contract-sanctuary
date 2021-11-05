pragma solidity ^0.8.0;

contract Token {
    string public name = "Runkus Coin";
    string public symbol = "RUNK";
    address public owner;
    uint public totalSupply = 1000000000000000;
    mapping(address => uint) balances;

    constructor() {
        owner = msg.sender;
        balances[msg.sender] = totalSupply;
    }

    function transfer(address to, uint amount) external {
        require(balances[msg.sender] >= amount, "Insufficient Runkus");
        balances[msg.sender] -= amount;
        balances[to] += amount;
    }

    function balanceOf(address account) external view returns (uint) {
        return balances[account];
    }


}