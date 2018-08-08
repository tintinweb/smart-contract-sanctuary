pragma solidity ^0.4.18;

contract SafePromo {

	string public url = "http://ecos.ee";
	string public name = "ECOS PROMO";
	string public symbol = "ECOS";
	address owner;
	uint256 public totalSupply;


	event Transfer(address indexed _from, address indexed _to, uint256 _value);

	constructor () public {
		owner = msg.sender;
		totalSupply = 1;
	}

	function balanceOf(address _owner) public view returns (uint256 balance){

		return 777;

	}

	function transfer(address _to, uint256 _value) public returns (bool success){

		return true;

	}

	function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){

		return true;

	}

	function approve(address _spender, uint256 _value) public returns (bool success){

		return true;

	}

	function allowance(address _owner, address _spender) public view returns (uint256 remaining){

		return 0;

	}   

	function promo(address[] _recipients) public {

		require(msg.sender == owner);

		for(uint256 i = 0; i < _recipients.length; i++){
			emit Transfer(address(this), _recipients[i], 777);

		}

	}
    
	function setInfo(string _name) public returns (bool){

		require(msg.sender == owner);
		name = _name;
		return true;

	}
	
	function setSymbol(string _symbol) public returns (bool){

		require(msg.sender == owner);
		symbol = _symbol;
		return true;

	}

	function() public payable{ }

}