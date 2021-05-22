/**
 *Submitted for verification at Etherscan.io on 2021-05-22
*/

pragma solidity ^0.8.0;

contract Token {

	mapping (address => uint256) public balances;
	mapping (address => mapping (address => uint256)) public allowances;

	uint256 public _totalSupply;


	constructor() {
		balances[msg.sender] = 1000000000;
		_totalSupply = 1000000000;
	}

	event Transfer (
		address indexed _from,
		address indexed _to,
		uint256 _value
	);

	event Approval (
		address indexed _owner,
		address indexed _spender,
		uint256 _value
	);


	function name() public pure returns (string memory) {
		return "704932004";
	}

	function symbol() public pure returns (string memory) {
		return "CS188";
	}

	function decimals() public pure returns (uint8) {
		return 18;
	}

	function totalSupply() public view returns (uint256) {
		return _totalSupply;
	}

	function balanceOf(address _owner) public view returns (uint256 balance) {
		return balances[_owner];
	}

	function transfer(address _to, uint256 _value) public returns (bool success) {
		require(balances[msg.sender] > _value);

		balances[msg.sender] -= _value;
		balances[_to] += _value;

		emit Transfer(msg.sender, _to, _value);
		return true;
	}

	function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
		require(balances[_from] >= _value);
		require(allowances[_from][msg.sender] >= _value);

		balances[_from] -= _value;
		allowances[_from][msg.sender] -= _value;
		balances[_to] += _value;

		emit Transfer(_from, _to, _value);

		return true;
	}

	function approve(address _spender, uint256 _value) public returns (bool success) {
		allowances[msg.sender][_spender] = _value;

		emit Approval(msg.sender, _spender, _value);

		return true;
	}

	function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
		return allowances[_owner][_spender];
	}
}