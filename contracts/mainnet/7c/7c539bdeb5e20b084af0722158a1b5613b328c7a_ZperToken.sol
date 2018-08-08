pragma solidity ^0.4.18;

contract ZperToken {

	address public owner;
	uint256 public totalSupply;
	uint256 public cap;
	string public constant name = "ZperToken";
	string public constant symbol = "ZPR";
	uint8 public constant decimals = 18;

	mapping (address => uint256) public balances;
	mapping (address => mapping (address => uint256)) public allowed;

	event Mint(address indexed to, uint256 amount);
	event Transfer(address indexed _from, address indexed _to, uint256 _value);
	event Approval(address indexed _owner, address indexed _spender, uint256 _value);
	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
	event Burn(address indexed burner, uint256 value);

	function ZperToken (address _owner, uint256 _totalSupply, uint256 _cap) public {
		require(_owner != address(0));
		require(_cap > _totalSupply && _totalSupply > 0);
		
		totalSupply = _totalSupply * (10 ** 18);
		cap = _cap * (10 ** 18);
		owner = _owner;

		balances[owner] = totalSupply;
	}

	modifier onlyOwner() {
		require(msg.sender == owner);
		_;
	}

	function transferOwnership(address newOwner) onlyOwner public {
		require(newOwner != address(0));
		owner = newOwner;
		emit OwnershipTransferred(owner, newOwner);
	}

	function transfer(address _to, uint256 _value) public returns (bool success) {
		require(balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]);
		balances[msg.sender] -= _value;
		balances[_to] += _value;
		emit Transfer(msg.sender, _to, _value);
		return true;
	}

	function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
		require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value
			   	&& balances[_to] + _value > balances[_to]);
		balances[_to] += _value;
		balances[_from] -= _value;
		allowed[_from][msg.sender] -= _value;
		emit Transfer(_from, _to, _value);
		return true;
	}

	function balanceOf(address _owner) public constant returns (uint256 balance) {
		return balances[_owner];
	}

	function approve(address _spender, uint256 _value) public returns (bool success) {
		allowed[msg.sender][_spender] = _value;
		emit Approval(msg.sender, _spender, _value);
		return true;
	}

	function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
		return allowed[_owner][_spender];
	}

	function mint(address _to, uint256 _amount) onlyOwner public returns (bool) {
		require(cap >= totalSupply + _amount);
		require(totalSupply + _amount > totalSupply && balances[_to] + _amount > balances[_to]);
		totalSupply += _amount;
		balances[_to] += _amount;
		emit Mint(_to, _amount);
		emit Transfer(address(0), _to, _amount);
		return true;
	}

	function burn(uint256 _value) public returns (bool) {
		require(_value <= balances[msg.sender]);
		balances[msg.sender] -= _value;
		totalSupply -= _value;
		emit Burn(msg.sender, _value);
		emit Transfer(msg.sender, address(0), _value);
		return true;
	}

	function batchTransfer(address[] _tos, uint256[] _amount) public returns (bool success) {
		require(_tos.length == _amount.length);
		uint256 i;
		uint256 sum = 0;
		for(i = 0; i < _amount.length; i++)
			sum += _amount[i];

		require(balances[msg.sender] >= sum);

		for(i = 0; i < _tos.length; i++)
			transfer(_tos[i], _amount[i]);

		return true;
	}
}