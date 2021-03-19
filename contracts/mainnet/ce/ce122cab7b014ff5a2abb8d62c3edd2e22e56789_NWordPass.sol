/**
 *Submitted for verification at Etherscan.io on 2021-03-19
*/

pragma solidity ^0.5.0;

// Contract details
//
// Name          : NWord Pass
// Symbol        : NWORD
// Total supply  : 1,000,000
// Decimals      : 18

contract SafeMath 
{

    function safeAdd(uint _a, uint _b) public pure returns (uint c) 
    {
        c = _a + _b;
        require(c >= _a);
    }

    function safeSub(uint _a, uint _b) public pure returns (uint c) 
    {
        require(_b <= _a);
        c = _a - _b;
    }

    function safeMul(uint _a, uint _b) public pure returns (uint c) 
    {
        c = _a * _b;
        require(_a == 0 || c / _a == _b);
    }

    function safeDiv(uint _a, uint _b) public pure returns (uint c) 
    {
        require(_b > 0);
        c = _a / _b;
    }
}

contract ERC20Interface
{
	function totalSupply() public view returns (uint256);
	function balanceOf(address _owner) public view returns (uint256 balance);
	function transfer(address _to, uint256 _value) public returns (bool success);
	function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
	function approve(address _spender, uint256 _value) public returns (bool success);
	function allowance(address _owner, address _spender) public view returns (uint256 remaining);

	event Transfer(address indexed _from, address indexed _to, uint256 _value);
	event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract NWordPass is ERC20Interface, SafeMath
{
	string public name;
	string public symbol;
	uint8 public decimals;

	uint256 _totalSupply;

	mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    constructor() public 
    {
    	name = "NWord Pass";
    	symbol = "NWORD";
        decimals = 18;
        
        _totalSupply = 1000000000000000000000000;

        balances[msg.sender] = _totalSupply;
    }

    function nwordPassCheck(address _address) public view returns (string memory)
    {
        if(balanceOf(_address) >= 1)
        {
            return "This address has the pass nigga";
        }
        
        return "This address does not have the n word pass";
    }

  	function totalSupply() public view returns (uint256) 
  	{
	    return _totalSupply;
  	}

  	function balanceOf(address _address) public view returns (uint256 balance) 
  	{
        return balances[_address];
    }

    function transfer(address _to, uint256 _value) public returns (bool success)
    {
        balances[msg.sender] = safeSub(balances[msg.sender], _value);
        balances[_to] = safeAdd(balances[_to], _value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success)
    {
        balances[_from] = safeSub(balances[_from], _value);
        allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender], _value);
        balances[_to] = safeAdd(balances[_to], _value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success)
    {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining)
    {
    	return allowed[_owner][_spender];
    }
}