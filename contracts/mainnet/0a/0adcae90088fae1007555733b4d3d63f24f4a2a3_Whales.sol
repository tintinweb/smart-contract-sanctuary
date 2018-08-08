pragma solidity ^0.4.11;


contract ERC20Standard {
	uint public totalSupply;
	
	string public name;
	uint8 public decimals;
	string public symbol;
	string public version;
	
	mapping (address => uint256) balances;
	mapping (address => mapping (address => uint)) allowed;

	//Fix for short address attack against ERC20
	modifier onlyPayloadSize(uint size) {
		assert(msg.data.length == size + 4);
		_;
	} 

	function balanceOf(address _owner) constant returns (uint balance) {
		return balances[_owner];
	}

	function transfer(address _recipient, uint _value) onlyPayloadSize(2*32) {
		require(balances[msg.sender] >= _value && _value > 0);
	    balances[msg.sender] -= _value;
	    balances[_recipient] += _value;
	    Transfer(msg.sender, _recipient, _value);        
    }

	function transferFrom(address _from, address _to, uint _value) {
		require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0);
        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
    }

	function approve(address _spender, uint _value) {
		allowed[msg.sender][_spender] = _value;
		Approval(msg.sender, _spender, _value);
	}

	function allowance(address _spender, address _owner) constant returns (uint balance) {
		return allowed[_owner][_spender];
	}

	//Event which is triggered to log all transfers to this contract&#39;s event log
	event Transfer(
		address indexed _from,
		address indexed _to,
		uint _value
		);
		
	//Event which is triggered whenever an owner approves a new allowance for a spender.
	event Approval(
		address indexed _owner,
		address indexed _spender,
		uint _value
		);

}

contract Whales is ERC20Standard {
	function Whales() {
		totalSupply = 1000000000*10**8;
		name = "Whales";
		decimals = 8;
		symbol = "WHL";
		version = "1.0";
		balances[msg.sender] = totalSupply;
	}
}