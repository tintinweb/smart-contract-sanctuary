/**
 *Submitted for verification at Etherscan.io on 2022-01-15
*/

pragma solidity ^0.5.16;

contract JOYToken {
	string  public name   = "Joy City"; // Token name
	uint8  public decimals = 18;  // Decimals
	string  public symbol = "JOY"; // Symbol
	string  public standard = "Joy City v1.0"; // Declare totalSupply variable
	uint256 public totalSupply; // Declare totalSupply variable

	event Transfer(
		address indexed _from,
		address indexed _to,
		uint256 _value
		);

	// approve event
	event Approval(
		address indexed _owner,
		address indexed _spender,
		uint256 _value
		);

	mapping(address => uint256) public balanceOf;
	mapping(address => mapping(address => uint256)) public allowance;

	constructor (uint256 _initialSupply) public {   // Token constructor
		balanceOf[msg.sender] = _initialSupply;		// allocate initial supply
		totalSupply = _initialSupply;

	}

	// Transfer function 
	function transfer(address _to, uint256 _value) public returns (bool success) {
		// Exception incase of insufficient balance
		require(balanceOf[msg.sender] >= _value);

		// Transfer token balance
		balanceOf[msg.sender] -= _value;
		balanceOf[_to] += _value;

		// Transfer Event
		emit Transfer(msg.sender, _to, _value);
	
		// Return a Boolean
		return true;

	}

	// Delegated Transfer
	// approve
	function approve(address _spender, uint256 _value) public returns (bool success) {
		// allowance
		allowance[msg.sender][_spender] = _value;
		// require(balanceOf[_spender] >= _value);

		emit Approval(msg.sender, _spender, _value);

		return true;

	}
	
	//transferFrom
	function transferFrom(address _from , address _to, uint256 _value) public returns (bool success) {
		// Require _from account has enough tokens
		require(balanceOf[_from] >= _value);
		// Require allowance is sufficient
		require(allowance[_from][msg.sender] >= _value);

		// Change the balance
		balanceOf[_from] -= _value;
		balanceOf[_to] += _value;	

		// Update the allowance
		allowance[_from][msg.sender] -= _value;

		// Transfer event
		emit Transfer(_from, _to, _value);
		
		return true;

	}

}