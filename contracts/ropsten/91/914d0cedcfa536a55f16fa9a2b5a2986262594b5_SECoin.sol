pragma solidity ^0.4.13;

contract SECoin 
{
    string public name;
    string public symbol;
    uint public totalSupply;
    uint public decimals = 10e18;
    mapping(address => uint) balances;
    address public owner;
    
    modifier onlyOwner 
    {
        require(owner == msg.sender);
        _;
    }
    
    constructor()
    {
        name = "Software Engineering Coin";
        symbol = "SEC";
        owner = msg.sender;
        totalSupply = 0;
    }
    
    function mint(address _investor, uint amount) onlyOwner
    {
        balances[_investor] += amount * decimals;
        totalSupply += amount * decimals;
    }
    
    function buy() payable
    {
        balances[msg.sender] += msg.value * decimals;
        totalSupply += msg.value * decimals;
    }
    
    function transfer(address _to, uint amount)
    {
        require(balances[msg.sender] >= amount);
        balances[_to] += amount;
        balances[msg.sender] -= amount;
    }
    
}