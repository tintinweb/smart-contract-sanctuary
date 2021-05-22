/**
 *Submitted for verification at Etherscan.io on 2021-05-22
*/

pragma solidity = 0.8.0;

contract Token{

	mapping (address => uint256) public balances;
	mapping (address => mapping(address => uint)) public allowances;

	function name() public view returns (string memory) {
		return "205526077";
	}

	function symbol() public view returns (string memory) {
		return "CS188";
	}

	function decimals() public view returns (uint8) {
		return 18;
	}

	function totalSupply() public view returns (uint256) {
		return 1000000;
	}

	function balanceOf(address _owner) public view returns (uint256 balance) {
		return balances[_owner];
	}

	function transfer(address _to, uint256 _value) public returns (bool success) {
		return transferFrom(msg.sender, _to, _value);
	}

	function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
		if(allowances[_from][_to] > _value) {
			allowances[_from][_to] = allowances[_from][_to] - _value;
			balances[_to] = balances[_to] + _value;
			emit Transfer(_from, _to, _value);
			return true;
		} else {
			return false;
		}
	}

	function approve(address _spender, uint256 _value) public returns (bool success) {
		if(allowances[msg.sender][_spender] >= _value){
			emit Approval(msg.sender, _spender, _value);
			return true;
		}
		return false;
	}

	function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
		return allowances[_owner][_spender];
	}

	constructor() public {
		balances[msg.sender] = balances[msg.sender] + 10;
	}

	event Transfer(address indexed _from, address indexed _to, uint256 _value);
	event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}