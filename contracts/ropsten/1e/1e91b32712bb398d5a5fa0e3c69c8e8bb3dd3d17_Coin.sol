pragma solidity ^0.4.21;

contract Coin
{
    address public minter;
    mapping (address => uint) public balances;
    uint public totalCoins;
    uint public i = 0;

    event Sent(address from, address to, uint amount);

    // This is the constructor whose code is
    // run only when the contract is created.
    function Coin(uint _totalCoins) public
    {
        totalCoins = _totalCoins;
        minter = msg.sender;
    }

    function mint(address receiver, uint amount) public
    {
        i = i + amount;
        if (msg.sender != minter && i > totalCoins) return;
        balances[receiver] += amount;
    }

    function send(address receiver, uint amount) public
    {
        if (balances[msg.sender] < amount) return;
        balances[msg.sender] -= amount;
        balances[receiver] += amount;
        emit Sent(msg.sender, receiver, amount);
    }
}