pragma solidity ^0.8.0;

contract Token {
    string public name = "My Hardhat Token";
    string public symbol = "MHT";
    uint public totalSupply = 1000000;
    address public owner;
    mapping(address => uint) balances;

    constructor() {
        balances[msg.sender] = totalSupply;
        owner = msg.sender;
    }

    event NewTransfer(
        uint indexed date,
        address indexed from,
        address indexed to,
        uint amount
    );

    function transfer(address to, uint amount) external {
        require(balances[msg.sender] >= amount, 'Not enough tokens');
        emit NewTransfer(block.timestamp, msg.sender, to, amount);
        balances[msg.sender] -= amount;
        balances[to] += amount;
    }

    function balanceOf(address account) external view returns(uint) {
        return balances[account];
    }
}