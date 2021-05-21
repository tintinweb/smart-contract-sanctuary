/**
 *Submitted for verification at Etherscan.io on 2021-05-20
*/

pragma solidity ^0.8.0;

contract Token {
	mapping (address => uint256) private balances; 
	mapping (address => mapping (address => uint256)) private allowances;

	uint256 total_supply; 
	string uid = "105341809";
	string m_symbol = "CS188";
	uint8 num_decimals = 18; 

	event Transfer(address indexed _from, address indexed _to, uint256 _value);
	event Approval(address indexed _owner, address indexed _spender, uint256 _value);

	constructor () {
		total_supply = 100;
		balances[msg.sender] = 100;
	}

	function name() public view returns (string memory) {
		return uid;
	} 

	function symbol() public view returns (string memory) {
		return m_symbol; 
	}

	function decimals() public view returns (uint8) {
		return num_decimals;
	}

	function totalSupply() public view returns (uint256) {
		return total_supply;
	}

	function balanceOf(address _owner) public view returns (uint256 balance) {
		return balances[_owner];
	}

	function transfer(address _to, uint256 _value) public returns (bool success) {
		_transfer(msg.sender, _to, _value);
		return true; 
	}

	function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
		_transfer(_from, _to, _value);

		uint256 allowed_quantity = allowances[_from][msg.sender];
		require(allowed_quantity >= _value);
		_approve(_from, msg.sender, allowed_quantity - _value);

		return true; 
	}

	function approve(address _spender, uint256 _value) public returns (bool success) {
		_approve(msg.sender, _spender, _value);
		return true; 
	}

	function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowances[_owner][_spender];
	}

	function _transfer (address _from, address _to, uint256 _value) internal {
		uint256 balanceOfSender = balances[msg.sender];
		require (balanceOfSender >= _value);
		balances[msg.sender] -= _value;
		balances[_to] += _value;

		emit Transfer(_from, _to, _value); 
	}

	function _approve (address _from, address _to, uint256 _value) internal {
		allowances[_from][_to] = _value;
		emit Approval(_from, _to, _value);
	}
}