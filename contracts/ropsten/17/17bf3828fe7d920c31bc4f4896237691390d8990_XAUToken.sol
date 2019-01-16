pragma solidity ^0.4.24;

contract Ownable {
	address public owner;
	constructor () public {
		owner = msg.sender;
	}

    modifier onlyOwner {
    	require(msg.sender == owner);
        _;
    }

    function transferOwnerShip(address newOwer) public onlyOwner {
    	owner = newOwer;
    }
}

library SafeMath {

	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
		require(b <= a);
		uint256 c = a - b;
		return c;
	}

	function add(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a + b;
		require(c >= a);
		return c;
	}
}

contract ERC20Interface {
	function totalSupply() public view returns (uint256);
	function balanceOf(address _address) public view returns (uint256);
	function transfer(address _to, uint256 _value) public returns (bool success);
	function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
	function allowance(address _owner, address _spender) public view returns (uint256 remaining);
	function approve(address _spender, uint256 _value) public returns (bool success);
	event Transfer(address indexed _from, address indexed _to, uint _value);
	event Approval(address indexed _owner, address indexed _spender, uint _value);
}

contract StandardToken is ERC20Interface {
	using SafeMath for uint256;
	uint public totalSupply;
	mapping (address => uint256) balances;
	mapping (address => mapping (address => uint256)) allowed;

	function totalSupply() public view returns (uint256) {
		return totalSupply;
	}

	function balanceOf(address _address) public view returns (uint256) {
		return balances[_address];
	}

	function transfer(address _to, uint256 _value) public returns (bool success) {
		require(address(0) !=_to);
		require(balances[msg.sender] >= _value);

		balances[msg.sender] = balances[msg.sender].sub(_value);
		balances[_to] = balances[_to].add(_value);
		emit Transfer(msg.sender, _to, _value);
		return true;
	}

	function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
		require(address(0) !=_to);
		require(balances[_from] >= _value);
		require(allowed[_from][msg.sender] >= _value);

		balances[_from] = balances[_from].sub(_value);
		balances[_to] = balances[_to].add(_value);
		allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
		emit Transfer(_from, _to, _value);
		return true;
	}

	function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
		return allowed[_owner][_spender];
	}

	function approve(address _spender, uint256 _value) public returns (bool success){
		allowed[msg.sender][_spender] = _value;
		emit Approval(msg.sender, _spender, _value);
		return true;
	}

}

contract XAUToken is StandardToken,Ownable {
	
	string constant public name = "XAUToken";
	string constant public symbol = "XAU";
	uint8 constant public decimals = 18;
	uint public totalSupply = 1*10**22;

	mapping (address => bool) public frozenAddress;
	event AddSupply(address indexed _to, uint _value);
	event Frozen(address _address, bool _freeze);

	constructor () public {
		balances[msg.sender] = totalSupply;
		emit Transfer(address(0), msg.sender, totalSupply);
	}

	function mine(address _to, uint256 _value) onlyOwner public returns (bool success) {
		totalSupply = totalSupply.add(_value);
		balances[_to] = balances[_to].add(_value);
		emit AddSupply(_to, _value);
		emit Transfer(address(0), _to, _value);
		return true;
	}

	function freezeAddress(address _address,bool _freeze) onlyOwner public returns (bool success){
		frozenAddress[_address] = _freeze;
		emit Frozen(_address, _freeze);
		return true;
	}

	function transfer(address _to, uint256 _value) public returns (bool success) {
		require(!frozenAddress[msg.sender]);
		return super.transfer(_to,_value);
	}

	function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
		require(!frozenAddress[_from]);
		return super.transferFrom(_from, _to, _value);
	}

}