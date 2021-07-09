/**
 *Submitted for verification at BscScan.com on 2021-07-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) { c = a + b; require(c >= a); }
    function sub(uint256 a, uint256 b) internal pure returns (uint256 c) { require(b <= a); c = a - b; }
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) { c = a * b; require(a == 0 || c / a == b); }
    function div(uint256 a, uint256 b) internal pure returns (uint256 c) { require(b > 0); c = a / b; }
}

interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address tokenOwner) external view returns (uint256 balance);
    function allowance(address tokenOwner, address spender) external view returns (uint256 remaining);
    function transfer(address to, uint256 tokens) external returns (bool success);
    function approve(address spender, uint256 tokens) external returns (bool success);
    function transferFrom( address from, address to, uint256 tokens) external returns (bool success);

    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval( address indexed tokenOwner, address indexed spender, uint256 tokens);
}

contract BEP20 is IBEP20 {
    using SafeMath for uint256;
    
    address public owner;
    string public symbol;
    string public name;
    uint8 public decimals;

    uint256 _totalSupply;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    // Constructor
    constructor() public 
    {
        owner = msg.sender;
        symbol = 'TTT'; 
        name = 'Trending Topic Token'; 
        decimals = 18; 
        _totalSupply = 1000000 * 10**uint256(decimals); 
        balances[owner] = _totalSupply; 
        emit Transfer(address(0), owner, _totalSupply);
    }

    function totalSupply() public override view returns (uint256) 
    {return _totalSupply.sub(balances[address(0)]);}

    function balanceOf(address tokenOwner) public override view returns (uint256 balance)
    {return balances[tokenOwner];}

    function transfer(address to, uint256 tokens) public override returns (bool success)
    { 
        balances[msg.sender] = balances[msg.sender].sub(tokens); 
        balances[to] = balances[to].add(tokens); 
        emit Transfer(msg.sender, to, tokens); 
        return true;
    }

    function approve(address spender, uint256 tokens) public override returns (bool success)
    { 
        allowed[msg.sender][spender] = tokens; 
        emit Approval(msg.sender, spender, tokens); 
        return true;
    }

    function transferFrom(address from, address to, uint256 tokens) public override returns (bool success) 
    { 
        balances[from] = balances[from].sub(tokens); 
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens); 
        balances[to] = balances[to].add(tokens); 
        emit Transfer(from, to, tokens); 
        return true;
    }

    function allowance(address tokenOwner, address spender) public override view returns (uint256 remaining)
    {return allowed[tokenOwner][spender];}
}