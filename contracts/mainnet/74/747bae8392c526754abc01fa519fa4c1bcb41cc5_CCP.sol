pragma solidity ^0.4.21;

contract ERC20 {
	function totalSupply() public view returns (uint256 totalSup);
	function balanceOf(address _owner) public view returns (uint256 balance);
	function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
	function allowance(address _owner, address _spender) public view returns (uint256 remaining);
	function approve(address _spender, uint256 _value) public returns (bool success);
	function transfer(address _to, uint256 _value) public returns (bool success);
	event Transfer(address indexed _from, address indexed _to, uint _value);
	event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract ERC223 {
	function transfer(address _to, uint256 _value, bytes _data) public returns (bool success);
	event Transfer(address indexed _from, address indexed _to, uint _value, bytes _data);
}

contract ERC223ReceivingContract {
	function tokenFallback(address _from, uint _value, bytes _data) public;
}

contract CCP is ERC223, ERC20 {
    
	using SafeMath for uint256;

	uint public constant _totalSupply = 2100000000e18;
	//starting supply of Token

	string public constant symbol = "CCP";
	string public constant name = "CCPAY COIN";
	uint8 public constant decimals = 18;

	mapping(address => uint256) balances;
	mapping(address => mapping(address => uint256)) allowed;

	constructor() public{
		balances[msg.sender] = _totalSupply;
		emit Transfer(0x0, msg.sender, _totalSupply);
	}

	function totalSupply() public view returns (uint256 totalSup) {
	return _totalSupply;
	}

	function balanceOf(address _owner) public view returns (uint256 balance) {
		return balances[_owner];
	}
    
	function transfer(address _to, uint256 _value) public returns (bool success) {
		require(
			!isContract(_to)
		);
		balances[msg.sender] = balances[msg.sender].sub(_value);
		balances[_to] = balances[_to].add(_value);
		emit Transfer(msg.sender, _to, _value);
		return true;
	}
    
	function transfer(address _to, uint256 _value, bytes _data) public returns (bool success){
		require(
			isContract(_to)
		);
		balances[msg.sender] = balances[msg.sender].sub(_value);
		balances[_to] = balances[_to].add(_value);
		ERC223ReceivingContract(_to).tokenFallback(msg.sender, _value, _data);
		emit Transfer(msg.sender, _to, _value, _data);
		return true;
	}
    
	function isContract(address _from) private view returns (bool) {
		uint256 codeSize;
		assembly {
			codeSize := extcodesize(_from)
		}
		return codeSize > 0;
	}
    
    
	function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
		require(
			balances[_from] >= _value
			&& _value > 0
		);
		balances[_from] = balances[_from].sub(_value);
		balances[_to] = balances[_to].add(_value);
		allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
		emit Transfer(_from, _to, _value);
		return true;
	}
    
	function approve(address _spender, uint256 _value) public returns (bool success) {
		require(
			(_value == 0) || (allowed[msg.sender][_spender] == 0)
		);
		allowed[msg.sender][_spender] = _value;
		emit Approval(msg.sender, _spender, _value);
		return true;
	}
    
	function allowance(address _owner, address _spender) public view returns (uint256 remain) {
		return allowed[_owner][_spender];
	}

	function () public payable {
		revert();
	}
    
	event Transfer(address  indexed _from, address indexed _to, uint256 _value);
	event Transfer(address indexed _from, address  indexed _to, uint _value, bytes _data);
	event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
	function mul(uint256 a, uint256 b) internal pure returns (uint256) {
		if (a == 0) {
			return 0;
		}
		uint256 c = a * b;
		assert(c / a == b);
		return c;
	}

	function div(uint256 a, uint256 b) internal pure returns (uint256) {
		// assert(b > 0); // Solidity automatically throws when dividing by 0
		uint256 c = a / b;
		// assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
		return c;
	}

	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
		assert(b <= a);
		return a - b;
	}

	function add(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a + b;
		assert(c >= a);
		return c;
	}
}