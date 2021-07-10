// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract TubblyToken {
	
	string public name = "TubblyToken";
	string public symbol = "TUBE";
	
	address public admin;
	address public saleAddress;

	uint256 public supply;

	mapping(address => uint256) public balanceOf;
	mapping(address => mapping(address => uint256)) public allowance;

	event Transfer(
		address indexed _from,
		address indexed _to ,
		uint256 _value
	);

	event Approval(
		address indexed _owner,
		address indexed _spender,
		uint256 _value
	);

	event Mint(
		address indexed _beneficiary,
		uint256 _value
	);

	constructor() {
		admin = msg.sender;
	}

	function writeSale(address _saleAddress) public returns (bool success) {
		require(msg.sender == admin, "Sender must be address");
		saleAddress = _saleAddress;
		return true;
	}

	function transfer (address _to, uint256 _value) public returns (bool success) {
		require(balanceOf[msg.sender] >= _value, 'Not enough funds');
		
		balanceOf[msg.sender] -= _value;
		balanceOf[_to] += _value;
		emit Transfer(msg.sender, _to, _value);
		return true;
	}

	function mint(address _beneficiary, uint256 _value) public returns (bool success) {
		require( msg.sender == saleAddress || msg.sender == admin, "Sender must be saleAddress or admin.");
		balanceOf[_beneficiary] += _value;
		supply += _value;
		emit Mint(_beneficiary, _value);
		return true;
	}

	function approve(address _spender, uint256 _value) public returns (bool success) {
		allowance[msg.sender][_spender] = _value;

		emit Approval(msg.sender, _spender, _value);
		return true;
	}

	function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
		require( balanceOf[_from] >= _value);
		require (allowance[_from][msg.sender] >= _value);

		balanceOf[_from] -= _value;
		balanceOf[_to] += _value;

		allowance[_from][msg.sender] -= _value;

		emit Transfer(_from, _to, _value);
		return true;
	}
	
			
}