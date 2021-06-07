/**
 *Submitted for verification at Etherscan.io on 2021-06-07
*/

pragma solidity ^0.5.16;

contract CatCoin{

	string public name = "Cat Coin";
	string public symbol = "CAT";

	uint public totalSupply;

	mapping(address => uint) public balanceOf;
	mapping(address => mapping(address => uint)) public allowance;

	constructor (uint _initialSupply) public {
		balanceOf[msg.sender] = _initialSupply;
		// allocate the initial supply
		totalSupply = _initialSupply;
	}

	event Transfer(address indexed _from, address indexed _to, uint _value);

	event Approval(address indexed _owner, address indexed _spender, uint256 _value);

	function transfer(address _to,uint _value) public returns (bool success) {
		// Exception if account doesn't have enough
		require(balanceOf[msg.sender] >= _value);		
		// Transfer the balance
		balanceOf[msg.sender] -= _value;
		balanceOf[_to] += _value;
		// reg Transfer event
		emit Transfer(msg.sender, _to, _value);
		// Returns a bool
        return true;
	}

	function approve(address _spender, uint _value) public returns (bool success) {
		allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
		return true;
	}

	function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
		// Require that _from has enough tokens
		require(_value <= balanceOf[_from]);
		// Require that allowance is big enough
        require(_value <= allowance[_from][msg.sender]);
        // Change the balance
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        //Update the allowance
        allowance[_from][msg.sender] -= _value;
        
		emit Transfer(_from, _to, _value);
		return true;
	}
}