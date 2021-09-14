/**
 *Submitted for verification at BscScan.com on 2021-09-13
*/

pragma solidity 0.8.7;

contract ExampleToken {
	string  public name = "Antex";
	string  public symbol = "Antex";
	uint256 public decimals = 18;
	uint256 public totalSupply=21000000;

	event Transfer(address indexed _from, address indexed _to, uint256 _value);
	event Approval(address indexed _owner, address indexed _spender, uint256 _value);

	mapping(address => uint256) public balanceOf;
	mapping(address => mapping(address => uint256)) public allowance;

	constructor (uint256 _initialSupply) {
        	balanceOf[msg.sender] = _initialSupply;
        	totalSupply = _initialSupply;
    	}

    	function transfer(address _to, uint256 _value) public returns (bool success) {
        	require(balanceOf[msg.sender] >= _value);
		// use safeMath here ;)
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
		// use safeMath here ;)
	        balanceOf[_from] -= _value;
	        balanceOf[_to] += _value;
	        allowance[_from][msg.sender] -= _value;
	        emit Transfer(_from, _to, _value);
	        return true;
    	}
}