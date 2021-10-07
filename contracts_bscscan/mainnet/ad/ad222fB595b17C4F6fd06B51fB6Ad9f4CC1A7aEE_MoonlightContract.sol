/**
 *Submitted for verification at BscScan.com on 2021-10-07
*/

/**
** File: MoonlightContract.sol
** Submitted for Verification & Construction of Token.
** Simple Contract for eCollidex Crazy Cats Game.
** The game requires the admin to send coins to the players. MLC is a currency in the game Crazy Cats made by eCollidex which can be acquired in 6 different methods. 
** Check out our whitepaper for more information. https://whitepaper.crazycats.io/
** Burn Address: 0x000000000000000000000000000000000000DEAD ** Was supposed to be embedded but may cause future collapse due to 3rd party exploits. Using other systems.
**/

pragma solidity ^0.8.2;

contract MoonlightContract
{
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    uint public totalSupply = 1000000000 * 10 ** 18;
    string public name = "Moonlight Coin";
    string public symbol = "MLC";
    uint public decimals = 18;
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    constructor() 
	{
        balances[msg.sender] = totalSupply;
    }
	
    function approve(address spender, uint value) public returns (bool) 
	{
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;   
    }
	
    function balanceOf(address owner) public returns(uint) 
	{
        return balances[owner];
    }
    
    function transfer(address to, uint value) public returns(bool) 
	{
        require(balanceOf(msg.sender) >= value, 'Not Enough Balance.');
		require(value <= 0, 'Invalid Transfer Parameter.');
        balances[to] += value;
        balances[msg.sender] -= value;
		emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint value) public returns(bool) 
	{
        require(balanceOf(from) >= value, 'Not Enough Balance.');
        require(allowance[from][msg.sender] >= value, 'Allowance is Low.');
		require(value <= 0, 'Invalid Transfer Parameter.');
        balances[to] += value;
        balances[from] -= value;
        emit Transfer(from, to, value);
        return true;   
    }
}