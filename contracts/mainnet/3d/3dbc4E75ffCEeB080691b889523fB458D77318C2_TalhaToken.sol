/**
 *Submitted for verification at Etherscan.io on 2021-05-25
*/

pragma solidity ^0.5.16;

contract TalhaToken {
	string  public name = "Talha Token";
	string  public symbol = "TALHA";

	uint256 public totalSupply;

	mapping(address => uint256) public balanceOf;
	mapping(address => mapping(address => uint256)) public allowance;

	/* Events */
	event Transfer(
		address indexed _from,
		address indexed _to,
		uint256 _value);

	event Approval(
		address indexed _owner,
		address indexed _spender,
		uint256 _value);

	/*Constructor*/
	constructor(uint256 _initialSupply) public {
		balanceOf[msg.sender] = _initialSupply;
		totalSupply = _initialSupply;
	}

	/*ERC20 Standard functions*/
	function transfer(address _to, uint256 _value) public returns (bool success) {
		require(balanceOf[msg.sender] >= _value);

		balanceOf[msg.sender] -= _value;
		balanceOf[_to] += _value;

		emit Transfer(msg.sender, _to, _value);

		return true;
	}

	function approve(address _spender, uint256 _value) public returns (bool success) {
		allowance[msg.sender][_spender] = _value;

		emit Approval(msg.sender, _spender, _value);

		return true;
	}

	function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
		require(_value <= balanceOf[_from]);
		require(_value <= allowance[_from][msg.sender]);

		balanceOf[_from] -= _value;
		balanceOf[_to] += _value;

		allowance[_from][msg.sender] -= _value;

		emit Transfer(_from, _to, _value);

		return true;
	}
}