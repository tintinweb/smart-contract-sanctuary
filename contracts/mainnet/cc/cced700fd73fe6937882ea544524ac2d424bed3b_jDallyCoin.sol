pragma solidity ^0.4.23;

contract Token {

	mapping(address => uint) balances;
	mapping (address => mapping (address => uint256)) allowed;
	uint public totalSupply;
	
	event Transfer(address indexed _from, address indexed _to, uint256 _value);
	event Approval(address indexed _owner, address indexed _spender, uint256 _value);
	
	
	// ERC20 spec required functions
	function totalSupply() constant returns (uint256 supply) {}
	
	function balanceOf(address _owner) constant returns (uint balance) {
        return balances[_owner];
    }
	
	function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }
	
	function approve(address _spender, uint _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }
	
	function transfer(address _to, uint _value) public returns (bool success) {
		if (balances[msg.sender] >= _value
		&& _value > 0
		&& balances[_to] + _value > balances[_to]) {
			balances[msg.sender] -= _value;
			balances[_to] += _value;					// add value to receiver&#39;s balance
			Transfer(msg.sender, _to, _value);
			return true;
		} else {
			return false;
		}
	}
	
	function transferFrom(address _to, address _from, uint _value) returns (bool success) {
		if (balances[_from] >= _value
		&& _value > 0
		&& allowed[_from][msg.sender] >= _value) {
			balances[_to] += _value;
			balances[_from] -= _value;
			allowed[_from][msg.sender] -= _value;
			Transfer(_from, _to, _value);
			return true;
        } else {
			return false;
		}
    }
    
}







contract jDallyCoin is Token {
	
	function() {
		//if ether is sent to this address, send it back.
		throw;
	}
	
	
	// declaration of constants
	string public name;
	string public symbol;
	uint8 public decimals;
	
	
	// main constructor for setting token properties/balances
	function jDallyCoin(
	) {
		totalSupply = 2130000000000000000000000;
		balances[msg.sender] = 2130000000000000000000000;
		name = "jDallyCoin";
		decimals = 18;
		symbol = "JDC";
	}
}