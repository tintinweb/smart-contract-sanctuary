/**
 *Submitted for verification at Etherscan.io on 2021-12-16
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract Token {

	string public name = "PS Token";
	string public symbol = "PST";
	uint public decimals = 18;
	uint public totalSupply = 1000000000000000000000000000;


	event Transfer(address indexed _from, address indexed _to, uint256 _value);
	event Approval(address indexed _owner, address indexed _spender, uint256 _value);

	mapping(address => uint) public balanceOf;
	mapping(address => mapping(address => uint)) public allowance;

	constructor() {
		balanceOf[msg.sender] = totalSupply;	
	}

	function transfer(address _to, uint256 _value) public returns (bool success) {
		require(balanceOf[msg.sender] >= _value);

		balanceOf[msg.sender] -= _value;
		balanceOf[_to] += _value;

		emit Transfer(msg.sender, _to, _value);

		return true;
	}

	function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
		require(balanceOf[msg.sender] >= _value);
		require(allowance[_from][msg.sender] >= _value);

		allowance[_from][msg.sender] -= _value;
		balanceOf[_from] -= _value;
		balanceOf[_to] += _value;

		emit Transfer(_from, _to, _value);

		return true;
	}

	function approve(address _spender, uint256 _value) public returns (bool success) {
		allowance[msg.sender][_spender] = _value;
		
		emit Approval(msg.sender, _spender, _value);

		return true;
	}
}