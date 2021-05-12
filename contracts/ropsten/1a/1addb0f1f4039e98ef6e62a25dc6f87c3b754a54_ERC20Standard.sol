/**
 *Submitted for verification at Etherscan.io on 2021-05-12
*/

pragma solidity ^0.4.11;

contract ERC20Standard {
	uint256 public totalSupply;
	string public name;
	uint256 public decimals;
	string public symbol;
	address public owner;

	mapping (address => uint256) balances;
	mapping (address => mapping (address => uint256)) allowed;

  function ERC20Standard(uint256 _totalSupply, string _symbol, string _name) public {
		decimals = 18;
		symbol = _symbol;
		name = _name;
		owner = msg.sender;
        totalSupply = _totalSupply * (10 ** decimals);
        balances[msg.sender] = totalSupply;
  }
	//Fix for short address attack against ERC20，避免短地址攻击
	modifier onlyPayloadSize(uint size) {
		assert(msg.data.length == size + 4);
		_;
	} 


	function balanceOf(address _owner) constant public returns (uint256) {
		return balances[_owner];
	}


	function transfer(address _recipient, uint256 _value) onlyPayloadSize(2*32) public {
		require(balances[msg.sender] >= _value && _value > 0);
	    balances[msg.sender] -= _value;
	    balances[_recipient] += _value;
	    Transfer(msg.sender, _recipient, _value);        
    }


	function transferFrom(address _from, address _to, uint256 _value) public {
		require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0);
        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
    }


	function approve(address _spender, uint256 _value) public {
		allowed[msg.sender][_spender] = _value;
		Approval(msg.sender, _spender, _value);
	}


	function allowance(address _owner, address _spender) constant public returns (uint256) {
		return allowed[_owner][_spender];
	}

	event Transfer(
		address indexed _from,
		address indexed _to,
		uint256 _value
		);
		
	event Approval(
		address indexed _owner,
		address indexed _spender,
		uint256 _value
		);
}