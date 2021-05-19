/**
 *Submitted for verification at Etherscan.io on 2021-05-19
*/

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

contract Token {
	string private _name;
	string private _symbol;
	uint256 private _totalSupply;
	uint8 private _decimals;

	mapping (address => uint256) private _balances;
	mapping (address => mapping (address => uint256)) private _allowed;

	event Transfer(address indexed _from, address indexed _to, uint256 _value);
	event Approval(address indexed _owner, address indexed _spender, uint256 _value);


	constructor() {
		_totalSupply = 100;
		_name = "305366728";
		_symbol = "CS188";
		_decimals = 18;
		_balances[msg.sender] = _totalSupply;
	}



	function name() public view returns (string memory) {
		return _name;
	}

	function symbol() public view returns (string memory) {
		return _symbol;
	}

	function decimals() public view returns (uint8) {
		return _decimals;
	}

	function totalSupply() public view returns (uint256) {
		return _totalSupply;
	}

	function balanceOf(address _owner) public view returns (uint256 balance) {
		return _balances[_owner];
	}

	function transfer(address _to, uint256 _value) public returns (bool success) {
		require(_balances[msg.sender] >= _value);
		require(_to != address(0));
		_balances[msg.sender] -= _value;
		_balances[_to] += _value;
		emit Transfer(msg.sender, _to, _value);
		return true;
	}

	function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
		uint256 _allowance = _allowed[_from][msg.sender];
		require(_balances[_from] >= _value && _allowance >= _value);
		require(_to != address(0));
		_balances[_from] -= _value;
		_balances[_to] += _value;
		_allowed[_from][msg.sender] -= _value;
		emit Transfer(_from, _to, _value);
		return true;		

	}

	function approve(address _spender, uint256 _value) public returns (bool success) {
		require(_spender != address(0));
		_allowed[msg.sender][_spender] = _value;
		emit Approval(msg.sender, _spender, _value);
		return true;
	}

	function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
		return _allowed[_owner][_spender];
	}



}