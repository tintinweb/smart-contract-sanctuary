pragma solidity ^0.4.13;

contract proverka6 {

	string public symbol = "PRV6";
	string public name = "proverka6";
	uint8 public constant decimals = 12;
	uint256 public totalSupply = 1000000000000;

	address owner;

	mapping (address => uint256) public balances;
	mapping (address => mapping (address => uint)) public allowed;

	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed _owner, address indexed _spender, uint _value);
 
	function proverka6() {
		owner = msg.sender;
		balances[owner] = totalSupply;
	}
    
	function sub(uint256 a, uint256 b) internal constant returns (uint256) {
		assert(b <= a);
		return a - b;
	}

	function add(uint256 a, uint256 b) internal constant returns (uint256) {
		uint256 c = a + b;
		assert(c >= a);
		return c;
	}

	function balanceOf(address _owner) constant returns (uint256 balance) {
		return balances[_owner];
	}	

	function transfer(address _to, uint256 _value) returns (bool) {
		require (_to != 0x0);
		balances[msg.sender] = sub(balances[msg.sender], _value);
		balances[_to] = add(balances[_to], _value);
		Transfer(msg.sender, _to, _value);
		return true;
	}

	function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
		require (_to != 0x0);
		require (_value < allowed[_from][msg.sender]);  
		balances[_to] = add(balances[_to], _value);
		balances[_from] = sub(balances[_from], _value);
		sub(allowed[_from][msg.sender], _value);
		Transfer(_from, _to, _value);
		return true;
	}

	function approve(address _spender, uint _value) returns (bool success) {
		allowed[msg.sender][_spender] = _value;
		Approval(msg.sender, _spender, _value);
		return true;
	}

	function allowance(address _owner, address _spender) constant returns (uint remaining) {
		return allowed[_owner][_spender];
	}

}