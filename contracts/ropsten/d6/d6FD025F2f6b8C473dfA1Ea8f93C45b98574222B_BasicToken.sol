/**
 *Submitted for verification at Etherscan.io on 2021-03-22
*/

pragma solidity 0.8.2;

library SafeMath {

	/*
	soma os parametros uint1 e uint2
	{pure} não usa blockchain
	@param uint {a}
	@param uint {b}
	@return uint 
	*/
	function add(uint a, uint b) internal pure returns(uint) {
		uint c = a + b;
		require(c > a, "Sum Ovwerflow!");

		return c;
	}

	/*
	subtrai os parametros uint1 e uint2
	{pure} não usa blockchain
	@param uint {a}
	@param uint {b}
	@return uint 
	*/
	function sub(uint a, uint b) internal pure returns(uint) {
		require(b <= a, "Sub Underflow!");
		uint c = a - b;

		return c;
	}

	/*
	multiplica os parametros uint1 e uint2
	{pure} não usa blockchain
	@param uint {a}
	@param uint {b}
	@return uint 
	*/
	function mult(uint a, uint b) internal pure returns(uint) {
		if (a == 0 || b == 0) {
			return 0;
		}
		uint c = a * b;
		require(c/a == b, "Mult Overflow!");

		return c;
	}

	/*
	multiplica os parametros uint1 e uint2
	{pure} não usa blockchain
	@param uint {a}
	@param uint {b}
	@return uint 
	*/
	function div(uint a, uint b) internal pure returns(uint) {
		uint c = a / b;

		return a / b;
	}

	/*
	eleva os elementos os parametros uint1 e uint2
	{pure} não consulta e nem altera a blockchain
	@param uint {num1}
	@param uint {num2}
	@return uint 
	*/
	function power(uint num1, uint num2) internal pure returns(uint) {
		return num1 ** num2;
	}
}

contract Ownable {
	address public owner;

	event OwnershipTransferred(address newOwner);

	constructor() public {	
		owner = msg.sender;
	}

	modifier onlyOwner() {
		require(msg.sender == owner, "You are not the Owner!");
		_;
	}

	function transferOwnership(address payable newOwner) onlyOwner public {
		owner = newOwner;

		emit OwnershipTransferred(owner);
	}

}

abstract contract ERC20 {
    function totalSupply() public virtual view returns (uint);
    function balanceOf(address tokenOwner) public virtual view returns (uint balance);
    function allowance(address tokenOwner, address spender) public virtual view returns (uint remaining);
    function transfer(address to, uint tokens) public virtual returns (bool success);
    function approve(address spender, uint tokens) public virtual returns (bool success);
    function transferFrom(address from, address to, uint tokens) public virtual returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract BasicToken is Ownable, ERC20 {
	using SafeMath for uint;

	uint internal _totalSupply;

	mapping(address => uint) internal _balances;
	mapping(address => mapping(address => uint)) internal _allowed;

	function totalSupply() override public view returns (uint) {
		return _totalSupply;
	}

    function balanceOf(address tokenOwner) override public view returns (uint balance) {
    	return _balances[tokenOwner];
    }

	function transfer(address to, uint tokens) override public returns (bool success) {
		require(_balances[msg.sender] >= tokens);
		require(to != address(0));

		_balances[msg.sender] = _balances[msg.sender].sub(tokens);
		_balances[to] = _balances[to].add(tokens);

		emit Transfer(msg.sender, to, tokens);

		return true;
	}

    function approve(address spender, uint tokens) override public returns (bool success) {
    	_allowed[msg.sender][spender] = tokens;
    	
    	emit Approval(msg.sender, spender, tokens);

    	return true;
    }

    function allowance(address tokenOwner, address spender) override public view returns (uint remaining) {
    	return _allowed[tokenOwner][spender];
    }

    function transferFrom(address from, address to, uint tokens) override public returns (bool success) {
    	require(_allowed[from][msg.sender] >= tokens);
    	require(_balances[from] >= tokens);
		require(to != address(0));

		_balances[from] = _balances[from].sub(tokens);
		_balances[to] = _balances[to].add(tokens);
		_allowed[from][msg.sender] = _allowed[from][msg.sender].sub(tokens);

		emit Transfer(from, to, tokens);

		return true;
    }

}

contract MintableToken is BasicToken {
	using SafeMath for uint;
	event Mint(address indexed to, uint tokens);

	function mint(address to, uint tokens) onlyOwner public {
		_balances[to] = _balances[to].add(tokens);
		_totalSupply = _totalSupply.add(tokens);

		emit Mint(to, tokens);
	}

}

contract TestCoin is MintableToken {
	string public constant name = "Test Coin"; // Token Name
	string public constant symbol = "TST"; // Token Symbol
	uint8 public constant decimals = 18; // Coin size
}