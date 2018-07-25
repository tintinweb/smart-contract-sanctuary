pragma solidity ^0.4.24;

interface ERC20
{
	function totalSupply() view external returns (uint _totalSupply);
	function balanceOf(address _owner) view external returns (uint balance);
	function transfer(address _to, uint _value) external returns (bool success);
	function transferFrom(address _from, address _to, uint _value) external returns (bool success);
	function approve(address _spender, uint _value) external returns (bool success);
	function allowance(address _owner, address _spender) view external returns (uint remaining);

	event Transfer(address indexed _from, address indexed _to, uint _value);
	event Approval(address indexed _owner, address indexed _spender, uint _value);
}

contract NoxusCoin is ERC20
{
	string public name;
	string public symbol;
	uint public totalSupply;
	uint8 public decimals = 18;	

	mapping (address => uint) public balanceOf;
	mapping (address => mapping (address => uint)) public allowance;

	event Transfer(address indexed from, address indexed to, uint value);
	event Burn(address indexed from, uint value);

	constructor(uint initialSupply,string tokenName, string tokenSymbol, address _owner) public
	{
		totalSupply = initialSupply * 10 ** uint(decimals);
		balanceOf[_owner] = totalSupply;
		name = tokenName;
		symbol = tokenSymbol;
	}

	function totalSupply() view external returns (uint _totalSupply)
	{
		return totalSupply;
	}
	function balanceOf(address _owner) view external returns (uint balance)
	{
		return balanceOf[_owner];
	}

	function allowance(address _owner, address _spender) view external returns (uint remaining)
	{
		return allowance[_owner][_spender];
	}
	function _transfer(address _from, address _to, uint _value) internal
	{
		require(_to != 0x0);
		require(balanceOf[_from] >= _value);
		require(balanceOf[_to] + _value > balanceOf[_to]);
		
		uint previousBalances = balanceOf[_from] + balanceOf[_to];
		balanceOf[_from] -= _value;
		balanceOf[_to] += _value;
		
		emit Transfer(_from, _to, _value);
		assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
	}

	function transfer(address _to, uint _value) public returns (bool success)
	{
		_transfer(msg.sender, _to, _value);
		return true;
	}

	function transferFrom(address _from, address _to, uint _value) public returns (bool success)
	{
		require(_value <= allowance[_from][msg.sender]);
		allowance[_from][msg.sender] -= _value;
		_transfer(_from, _to, _value);
		return true;
	}

	function approve(address _spender, uint _value) public returns (bool success)
	{
		allowance[msg.sender][_spender] = _value;
		emit Approval(msg.sender, _spender, _value);
		return true;
	}

	function burn(uint _value) public returns (bool success)
	{
		require(balanceOf[msg.sender] >= _value);
		balanceOf[msg.sender] -= _value;
		totalSupply -= _value;
		emit Burn(msg.sender, _value);
		return true;
	}

	function burnFrom(address _from, uint _value) public returns (bool success)
	{
		require(balanceOf[_from] >= _value);
		require(_value <= allowance[_from][msg.sender]);
		balanceOf[_from] -= _value;
		allowance[_from][msg.sender] -= _value;
		totalSupply -= _value;
		emit Burn(_from, _value);
		return true;
	}
	
	function () public
	{
		revert();
	}
}