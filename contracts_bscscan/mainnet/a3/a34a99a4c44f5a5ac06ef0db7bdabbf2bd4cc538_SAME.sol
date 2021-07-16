/**
 *Submitted for verification at BscScan.com on 2021-07-16
*/

pragma solidity ^0.5.0;

contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function transfer(address to, uint tokens) public returns(bool success);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract SafeMath
{
    function safeAdd(uint a, uint b) public pure returns (uint c)
    {
        c=a+b;
        require(c>=a);
    }
    function safeSub (uint a, uint b) public pure returns (uint c)
    {
        require (b<=a); c=a-b;
    }
    function safeMul (uint a, uint b) public pure returns (uint c) 
    {
        c = a * b;
        require (a == 0 || c / a == b);
    }
    function safeDiv (uint a, uint b) public pure returns (uint c) 
    {
        require (b > 0);
        c = a / b;
    }
    
}

contract SAME is ERC20Interface, SafeMath
    {
        string public name;
        string public symbol;
        uint8 public decimals;
        uint256 public _totalSupply;
        
        mapping (address => uint) balances;
        mapping (address => mapping (address => uint)) allowed;
        
        constructor() public 
        {
		
		name = "SpaceMoney";
		symbol = "SAME";
		decimals = 6;
		_totalSupply = 100000000000000000;
		
		balances[msg.sender] = _totalSupply;
		emit Transfer (address(0), msg.sender, _totalSupply);
        }
        
        function totalSupply() public view returns (uint)
        {
            return _totalSupply - balances[address(0)];
        }
        
        function balanceOf(address tokenOwner) public view returns (uint balance)
        {
            return balances[tokenOwner];
        }
        
        function transfer(address to, uint tokens) public returns (bool success)
        {
            balances[msg.sender] = safeSub(balances[msg.sender], tokens);
            balances[to] = safeAdd(balances[to], tokens);
            emit Transfer(msg.sender, to, tokens);
            return true;
        }
    }