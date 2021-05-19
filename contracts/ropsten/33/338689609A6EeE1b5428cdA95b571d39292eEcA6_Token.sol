/**
 *Submitted for verification at Etherscan.io on 2021-05-19
*/

pragma solidity ^0.8.0;

contract Token{

	address public owner;

	uint256 private _totalSupply;

	mapping (address => uint256) private _balances;

	mapping (address => mapping (address => uint256)) private _allowed;

	constructor() public{
		owner=msg.sender;
		_totalSupply=9000000000000000000;
		_balances[msg.sender]=_totalSupply;
	}

	event Transfer(address indexed _from, address indexed _to, uint256 _value);

	event Approval(address indexed _owner, address indexed _spender, uint256 _value);

	function sub(uint256 a, uint256 b) internal pure returns (uint256){
		assert (b<=a);
		return a-b;
	}

	function add(uint256 a, uint256 b) internal pure returns (uint256){
		uint256 c = a + b;
		assert (c >= a);
		return c;
	}

	function name() public view returns (string memory){
	 	return "604757623";
	}

	function symbol() public view returns (string memory){
		return "CS188";
	}

	function decimals() public view returns (uint8){
		return 18;
	}

	function totalSupply() public view returns (uint256){
		return _totalSupply;
	}

	function balanceOf(address _owner) public view returns (uint256 balance){
		return _balances[_owner];
	}

	function transfer(address _to, uint256 _value) public returns (bool success){
		require(_value <= _balances[msg.sender]);
		require (_to != address(0));

		_balances[msg.sender]=sub(_balances[msg.sender],_value);
		emit Transfer(msg.sender,_to,_value);
		return true;
	}

	function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){
		require(_value <= _balances[_from]);
		require(_value <= _allowed[_from][msg.sender]);	
		require(_to != address(0));

		_balances[_from] = sub(_balances[_from], _value);
		_balances[_to] = add(_balances[_to], _value);
		_allowed[_from][msg.sender] = sub(_allowed[_from][msg.sender],_value);
		emit Transfer(_from,_to,_value);
		return true;
	}

	function approve(address _spender, uint256 _value) public returns (bool success){
		require (_spender != address(0));
		_allowed[msg.sender][_spender]=_value;
		emit Approval(msg.sender,_spender,_value);
		return true;
	}

	function allowance(address _owner, address _spender) public view returns (uint256 remaining){
		return _allowed[_owner][_spender];
	}

	}