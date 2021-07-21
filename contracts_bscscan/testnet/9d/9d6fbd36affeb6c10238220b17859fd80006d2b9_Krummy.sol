pragma solidity ^0.8.6;

import "./SafeMath.sol";

contract Krummy {

	using SafeMath for uint256;

	string public constant name = "Krummy";
	string public constant symbol = "KPYM";
	uint8 public constant decimals = 0;
	uint256 public constant totalSupply = 10 ** 6; // 1 million
	address public immutable owner;
	mapping (address => uint256) public balances;
	mapping (address => mapping (address => uint256)) public allowed;

	event Transfer(address indexed _from, address indexed _to, uint256 _value);
	event Approval(address indexed _owner, address indexed _spender, uint256 _value);

	constructor() {
		owner = msg.sender;
		balances[msg.sender] = totalSupply;
		emit Transfer(address(0), msg.sender, totalSupply);
	}

	function balanceOf(address _owner) public view returns (uint256 balance) {
		return balances[_owner];
	}

	function transfer(address _to, uint256 _value) public returns (bool success) {
		require(balances[msg.sender] >= _value, "Not enough balance");

		balances[msg.sender] = balances[msg.sender].sub(_value);
		balances[_to] = balances[_to].add(_value);

		emit Transfer(msg.sender, _to, _value);
		return true;
	}

	function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
		require(allowed[_from][msg.sender] >= _value, "Not allowed to transfer this amount");
		require(balances[_from] >= _value, "Not enough balance");

		balances[_from] = balances[_from].sub(_value);
		balances[_to] = balances[_to].add(_value);

		allowed[_from][msg.sender] = allowed[_from][msg.sender].add(_value);

		emit Transfer(_from, _to, _value);
		return true;
	}

	function approve(address _spender, uint256 _value) public returns (bool success) {
		allowed[msg.sender][_spender] = _value;
		emit Approval(msg.sender, _spender, _value);
		return true;
	}

	function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
		return allowed[_owner][_spender];
	}

}