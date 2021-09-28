/**
 *Submitted for verification at Etherscan.io on 2021-09-28
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

interface ERC20Interface {
	function totalSupply() external view returns (uint256 supply);
	function balanceOf(address _owner ) external view returns (uint256 balance);

	//Note Transfers of 0 values MUST be treated as normal transfers and fire the Transfer event.	
	function transfer(address _to, uint256 _value) external returns (bool success);

	function allowance(address _owner, address _spender) external view returns (uint256 remaining);
	function approve(address _spender, uint256 _value) external returns (bool sucess);
	function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);

	event Transfer(address indexed _from, address indexed _to, uint256 _value);
	event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract FilmToken is ERC20Interface {

	// public variable will have a same getter function the same name as variable
	string public name = "Film Token";
	string public symbol = "FILM";
	uint8 public decimals = 4;
	uint256 public override  totalSupply;

	address public founder;
	mapping(address => uint256) public balances;
	mapping(address => mapping(address => uint256)) allowed;

	constructor() {
		totalSupply = 10000000000000000;
		founder = msg.sender;
		balances[founder] = totalSupply;
	}

	function balanceOf(address _owner) public view override returns (uint256) {
		return balances[_owner]; 
	}

	function transfer(address _to, uint256 _value) public override returns(bool succcess) {
		require(balances[msg.sender] >= _value);
		balances[_to] += _value;
		balances[msg.sender] -= _value;
		emit Transfer(msg.sender, _to, _value);

		return true;
	}
	
	function allowance(address _owner, address _spender) public override view returns (uint256 remaining) {
	    return allowed[_owner][_spender];
	}
	
	function approve(address _spender, uint256 _value) public override returns (bool sucess) {
		    require(balances[msg.sender]>=_value && _value > 0);
		    allowed[msg.sender][_spender] = _value;
		    
		    emit Approval(msg.sender,_spender,_value);
		    return true;
	}
	
	function transferFrom(address _from, address _to, uint256 _value) public override returns (bool success) {
	    require(balances[_from] >= _value);
	    require(allowed[_from][_to] >= _value);
	    
	    balances[_from] -= _value;
	    balances[_to]   += _value;
	    allowed[_from][_to] -=_value;
	    
	    return true;
	}
	
}