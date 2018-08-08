pragma solidity ^0.4.24;

library SafeMath {
	function add(uint a, uint b) internal pure returns (uint c) {
		c = a + b;
		require(c >= a);
	}

	function sub(uint a, uint b) internal pure returns (uint c) {
		require(b <= a);
		c = a - b;
	}
}

contract ERC20Interface {
	function totalSupply() public constant returns (uint);
	function balanceOf(address tokenOwner) public constant returns (uint balance);
	function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
	function transfer(address to, uint tokens) public returns (bool success);
	function approve(address spender, uint tokens) public returns (bool success);
	function transferFrom(address from, address to, uint tokens) public returns (bool success);

	event Transfer(address indexed from, address indexed to, uint tokens);
	event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract DrupeCoin is ERC20Interface {
	using SafeMath for uint;

	string public constant symbol = "DPC";
	string public constant name = "DrupeCoin";
	uint8 public constant decimals = 18;

	uint _initialSupply;
	mapping(address => uint) _balances;
	mapping(address => mapping(address => uint)) _allowed;

	constructor() public {
		_initialSupply = 200 * 1000000 * 10**uint(decimals);
		_balances[msg.sender] = _initialSupply;
		emit Transfer(address(0), msg.sender, _initialSupply);
	}

	function _transfer(address from, address to, uint tokens) internal {
		_balances[from] = _balances[from].sub(tokens);
		_balances[to] = _balances[to].add(tokens);
		emit Transfer(from, to, tokens);
	}

	function totalSupply() public constant returns (uint) {
		return _initialSupply - _balances[address(0)];
	}

	function balanceOf(address tokenOwner) public constant returns (uint balance) {
		return _balances[tokenOwner];
	}

	function transfer(address to, uint tokens) public returns (bool success) {
		_transfer(msg.sender, to, tokens);
		return true;
	}

	function approve(address spender, uint tokens) public returns (bool success) {
		_allowed[msg.sender][spender] = tokens;
		emit Approval(msg.sender, spender, tokens);
		return true;
	}

	function transferFrom(address from, address to, uint tokens) public returns (bool success) {
		_allowed[from][msg.sender] = _allowed[from][msg.sender].sub(tokens);
		_transfer(from, to, tokens);
		return true;
	}

	function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
		return _allowed[tokenOwner][spender];
	}
}