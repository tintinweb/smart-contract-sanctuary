pragma solidity ^0.4.20;

library SafeMath
{
	function mul(uint a, uint b) internal pure returns (uint)
	{
		if (a == 0)
		{
			return 0;
		}
		uint c = a * b;
		assert(c / a == b);
		return c;
	}

	function div(uint a, uint b) internal pure returns (uint)
	{
		uint c = a / b;
		return c;
	}

	function sub(uint a, uint b) internal pure returns (uint)
	{
		assert(b <= a);
		return a - b;
	}

	function add(uint a, uint b) internal pure returns (uint)
	{
		uint c = a + b;
		assert(c >= a);
		return c;
	}
}

interface ERC20
{
	function balanceOf(address who) public view returns (uint);
	function transfer(address to, uint value) public returns (bool);
	function allowance(address owner, address spender) public view returns (uint);
	function transferFrom(address from, address to, uint value) public returns (bool);
	function approve(address spender, uint value) public returns (bool);
	event Transfer(address indexed from, address indexed to, uint value);
	event Approval(address indexed owner, address indexed spender, uint value);
}

interface ERC223
{
	function transfer(address to, uint value, bytes data) public;
	event Transfer(address indexed from, address indexed to, uint value, bytes indexed data);
}

contract ERC223ReceivingContract
{
	function tokenFallback(address _from, uint _value, bytes _data) public;
}

contract StandardToken is ERC20, ERC223
{
	using SafeMath for uint;

	string public name;
	string public symbol;
	uint8 public decimals;
	uint public totalSupply;

	mapping (address => uint) balances;
	mapping (address => mapping (address => uint)) allowed;

	function StandardToken(string _name, string _symbol, uint8 _decimals, uint _totalSupply, address _admin) public
	{
		name = _name;
		symbol = _symbol;
		decimals = _decimals;
		totalSupply = _totalSupply * 10 ** uint(_decimals);
		balances[_admin] = totalSupply;
	}

	function tokenFallback(address _from, uint _value, bytes _data)
	{
	    revert();
	}
	
	function () //revert any ether sent to this contract
	{
		revert();
	}
	
	function balanceOf(address _owner) public view returns (uint balance)
	{
		return balances[_owner];
	}

	function transfer(address _to, uint _value) public returns (bool)
	{
		require(_to != address(0));
		require(_value <= balances[msg.sender]);
		balances[msg.sender] = SafeMath.sub(balances[msg.sender], _value);
		balances[_to] = SafeMath.add(balances[_to], _value);
		Transfer(msg.sender, _to, _value);
		return true;
	}

	function transferFrom(address _from, address _to, uint _value) public returns (bool)
	{
		require(_to != address(0));
		require(_value <= balances[_from]);
		require(_value <= allowed[_from][msg.sender]);

		balances[_from] = SafeMath.sub(balances[_from], _value);
		balances[_to] = SafeMath.add(balances[_to], _value);
		allowed[_from][msg.sender] = SafeMath.sub(allowed[_from][msg.sender], _value);
		Transfer(_from, _to, _value);
		return true;
	}

	function approve(address _spender, uint _value) public returns (bool)
	{
		allowed[msg.sender][_spender] = _value;
		Approval(msg.sender, _spender, _value);
		return true;
	}

	function allowance(address _owner, address _spender) public view returns (uint)
	{
		return allowed[_owner][_spender];
	}

	function increaseApproval(address _spender, uint _addedValue) public returns (bool)
	{
		allowed[msg.sender][_spender] = SafeMath.add(allowed[msg.sender][_spender], _addedValue);
		Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
		return true;
	}

	function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool)
	{
		uint oldValue = allowed[msg.sender][_spender];
		if (_subtractedValue > oldValue)
		{
			allowed[msg.sender][_spender] = 0;
		}
		else
		{
			allowed[msg.sender][_spender] = SafeMath.sub(oldValue, _subtractedValue);
		}
		Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
		return true;
	}
	
	function transfer(address _to, uint _value, bytes _data) public
	{
		require(_value > 0 );
		if(isContract(_to))
		{
			ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
			receiver.tokenFallback(msg.sender, _value, _data);
		}
		balances[msg.sender] = balances[msg.sender].sub(_value);
		balances[_to] = balances[_to].add(_value);
		Transfer(msg.sender, _to, _value, _data);
	}
		
	function isContract(address _addr) private returns (bool is_contract)
	{
		uint length;
		assembly
		{
			length := extcodesize(_addr)
		}
		return (length>0);
	}
}