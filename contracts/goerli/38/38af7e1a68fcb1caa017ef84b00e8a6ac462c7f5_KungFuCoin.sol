/**
 *Submitted for verification at Etherscan.io on 2021-08-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

contract KungFuCoin {
	string constant public name = "KungFuCoin";
	string constant public symbol = "KFC";
	uint256 constant public decimals = 18;
	uint256 constant public totalSupply = 5*10**26;
	
	mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
	
	function balanceOf(address _owner) public view returns (uint256 balance) {
	    return balances[_owner];
	}
	
	function transfer(address _to, uint256 _value) public returns (bool success) {
	    require(balances[msg.sender] >= _value);
	    require(balances[_to] + _value > balances[_to]);
	    balances[msg.sender] -= _value;
	    balances[_to] += _value;
	    emit Transfer(msg.sender, _to, _value);
	    return true;
	}
	
	function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
	    require(allowed[_from][msg.sender] >= _value);
	    require(balances[_from] >= _value);
	    require(balances[_to] + _value > balances[_to]);
	    allowed[_from][msg.sender] -= _value;
	    balances[_from] -= _value;
	    balances[_to] += _value;
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

	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed owner, address indexed spender, uint256 value);
}