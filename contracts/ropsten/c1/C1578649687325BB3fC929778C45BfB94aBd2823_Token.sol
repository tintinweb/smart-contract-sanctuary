pragma solidity ^0.8.7;

contract Token{
    string public name = "Amir";
    string public symbol = "AMR";
    address public owner;
    uint public totalSupply = 100000000000;
    uint public constant decimals = 8;
    mapping(address => uint) balances;

    constructor(){
        owner = msg.sender;
        balances[msg.sender] = totalSupply;
    }

    function transfer(address to, uint amount) external {
        require(balances[msg.sender] >= amount, 'Not enough tokens');
        // Deduct from sender, Add to receiver 
        balances[msg.sender] -= amount;
        balances[to] += amount;
    }

    function balanceOf(address account) external view returns (uint) {
        return balances[account];
    }

}