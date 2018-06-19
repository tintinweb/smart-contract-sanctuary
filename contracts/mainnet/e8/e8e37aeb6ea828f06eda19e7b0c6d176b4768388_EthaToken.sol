pragma solidity ^0.4.18;

contract ERC20Interface {
	uint256 public totalSupply;
	function balanceOf(address _owner) public constant returns (uint balance); // Get the account balance of another account with address _owner
	function transfer(address _to, uint256 _value) public returns (bool success); // Send _value amount of tokens to address _to
	function transferFrom(address _from, address _to, uint256 _value) public returns (bool success); // Send _value amount of tokens from address _from to address _to
	function approve(address _spender, uint256 _value) public returns (bool success);
	function allowance(address _owner, address _spender) public constant returns (uint256 remaining); // Returns the amount which _spender is still allowed to withdraw from _owner
	event Transfer(address indexed _from, address indexed _to, uint256 _value); // Triggered when tokens are transferred.
	event Approval(address indexed _owner, address indexed _spender, uint256 _value); // Triggered whenever approve(address _spender, uint256 _value) is called.
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
	function mul(uint256 a, uint256 b) internal constant returns (uint256) {
		uint256 c = a * b;
		assert(a == 0 || c / a == b);
		return c;
	}

	function div(uint256 a, uint256 b) internal constant returns (uint256) {
		// assert(b > 0); // Solidity automatically throws when dividing by 0
		uint256 c = a / b;
		// assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
		return c;
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
}
contract ERC20Token is ERC20Interface {
	using SafeMath for uint256;

	mapping (address => uint) balances;
	mapping (address => mapping (address => uint256)) allowed;

	modifier onlyPayloadSize(uint size) {
		require(msg.data.length >= (size + 4));
		_;
	}

	function () public{
		revert();
	}

	function balanceOf(address _owner) public constant returns (uint balance) {
		return balances[_owner];
	}
	function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
		return allowed[_owner][_spender];
	}

	function transfer(address _to, uint _value) public onlyPayloadSize(2 * 32) returns (bool success) {
		_transferFrom(msg.sender, _to, _value);
		return true;
	}
	function transferFrom(address _from, address _to, uint256 _value) public onlyPayloadSize(3 * 32) returns (bool) {
		allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
		_transferFrom(_from, _to, _value);
		return true;
	}
	function _transferFrom(address _from, address _to, uint256 _value) internal {
		require(_value > 0);
		balances[_from] = balances[_from].sub(_value);
		balances[_to] = balances[_to].add(_value);
		Transfer(_from, _to, _value);
	}

	function approve(address _spender, uint256 _value) public returns (bool) {
		require((_value == 0) || (allowed[msg.sender][_spender] == 0));
		allowed[msg.sender][_spender] = _value;
		Approval(msg.sender, _spender, _value);
		true;
	}
}

contract owned {
	address public owner;

	function owned() public {
		owner = msg.sender;
	}

	modifier onlyOwner {
		if (msg.sender != owner) revert();
		_;
	}

	function transferOwnership(address newOwner) public onlyOwner {
		owner = newOwner;
	}
}


contract EthaToken is ERC20Token, owned{
	using SafeMath for uint256;

	string public name = &#39;ETHA&#39;;
	string public symbol = &#39;ETHA&#39;;
	uint8 public decimals = 4;

	function EthaToken() public {
		balances[this] = totalSupply = 30000000000000000;
	}

	function setTokens(address target, uint256 _value) public onlyOwner {
		balances[this] = balances[this].sub(_value);
		balances[target] = balances[target].add(_value);
		Transfer(this, target, _value);
	}

	function mintToken(uint256 mintedAmount) public onlyOwner {
		totalSupply = totalSupply.add(mintedAmount);
		balances[this] = balances[this].add(mintedAmount);
	}

	function withdrawalTokens(address _from, address _to, uint256 _value) public onlyOwner {
		balances[_from] = balances[_from].sub(_value);
		balances[_to] = balances[_to].add(_value);
		Transfer(_from, _to, _value);
	}
}