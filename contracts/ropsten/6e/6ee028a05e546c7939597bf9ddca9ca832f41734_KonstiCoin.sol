/**
 *Submitted for verification at Etherscan.io on 2021-11-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract KonstiCoin {
	string private _name = 'KonstiCoin';
	string private _symbol = 'KONSTI';
	uint8 private _decimals = 15;
	mapping (address => uint256) private _balanceOf;
	mapping (address => mapping (address => uint256)) private _allowance;
	address public owner;

	event Transfer(address indexed _from, address indexed _to, uint256 _value);
	event Approval(address indexed _owner, address indexed _spender, uint256 _value);

	constructor() {
		owner = msg.sender;		
	}

	receive() external payable {
		deposit();
	}

	function name() external view returns (string memory) {
		return _name;
	}

	function symbol() external view returns (string memory) {
		return _symbol;
	}

	function decimals() external view returns (uint8) {
		return _decimals;
	}

	function totalSupply() external view returns (uint256) {
		return address(this).balance;
	}

	function balanceOf(address _owner) external view returns (uint256 balance) {
		return _balanceOf[_owner];
	}

	function transfer(address _to, uint256 _value) external returns (bool success) {
		return transferFrom(msg.sender, _to, _value);
	}

	function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
		require(_balanceOf[_from] >= _value, 'KonstiCoin: transfer value exceeds balance');
		if (msg.sender != _from) {
			require(_allowance[_from][msg.sender] >= _value, 'KonstiCoin: transfer value exceeds allowance');
			_allowance[_from][msg.sender] -= _value;
		}
		_balanceOf[_from] -= _value;
		if (_to != address(this)) {
			_balanceOf[_to] += _value;
			emit Transfer(_from, _to, _value);
		} else {
			payable(_from).transfer(_value);
			emit Transfer(_from, address(0), _value);
		}
		return true;
	}

	function approve(address _spender, uint256 _value) external returns (bool success) {
		_allowance[msg.sender][_spender] = _value;
		emit Approval(msg.sender, _spender, _value);
		return true;
	}

	function allowance(address _owner, address _spender) external view returns (uint256 remaining) {
		return _allowance[_owner][_spender];
	}

	function deposit() public payable {
		require(msg.sender == owner, 'KonstiCoin: sender is not owner');
		_balanceOf[msg.sender] += msg.value;
		emit Transfer(address(0), msg.sender, msg.value);
	}

	function withdraw(uint256 _value) public {
		require(_balanceOf[msg.sender] >= _value, 'KonstiCoin: withdraw value exceeds balance');
		_balanceOf[msg.sender] -= _value;
		payable(msg.sender).transfer(_value);
		emit Transfer(msg.sender, address(0), _value);
	}
}