/**
 *Submitted for verification at Etherscan.io on 2021-05-25
*/

pragma solidity ^0.5.0;

/* ----------------------------------------------------------------------------
* HEDGE STABLE FINANCE (HDSF)
* Site: https://www.hedge.to/
* Total: 243,633,197 tokens
---------------------------------------------------------------------------- */ 

// ERC20 token standart interface
contract ERC20Interface {
	function totalSupply() public view returns (uint);
	function balanceOf(address tokenOwner) public view returns (uint balance);
	function allowance(address tokenOwner, address spender) public view returns (uint remaining);
	function transfer(address to, uint tokens) public returns (bool success);
	function approve(address spender, uint tokens) public returns (bool success);
	function transferFrom(address from, address to, uint tokens) public returns (bool success);

	event Transfer(address indexed from, address indexed to, uint tokens);
	event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

// ----------------------------------------------------------------------------
// Safe Math Library
// ----------------------------------------------------------------------------
contract SafeMath {
	function safeAdd(uint a, uint b) public pure returns (uint c) {
		c = a + b;
		require(c >= a);
	}
	function safeSub(uint a, uint b) public pure returns (uint c) {
		require(b <= a); c = a - b; } function safeMul(uint a, uint b) public pure returns (uint c) { c = a * b; require(a == 0 || c / a == b); } function safeDiv(uint a, uint b) public pure returns (uint c) { require(b > 0);
		c = a / b;
	}
}


contract HDSF is ERC20Interface, SafeMath {
	string public name;
	string public symbol;
	uint8 public decimals; // Number of decimal places

	uint256 public _totalSupply;

	mapping(address => uint) balances;
	mapping(address => mapping(address => uint)) allowed;

	/**
	 * Constructor
	 * Initializes contract with initial supply tokens to the creator of the contract
	 */
	constructor() public {
		name = "HEDGE STABLE FINANCE";
		symbol = "HDSF";
		decimals = 18;
		_totalSupply = 243633197 * 10 ** 18;

		balances[msg.sender] = _totalSupply;
		emit Transfer(address(0), msg.sender, _totalSupply);
	}

	// Total token offer
	function totalSupply() public view returns (uint) {
		return _totalSupply  - balances[address(0)];
	}
	
	// This option shows the amount of funds in the account.
	function balanceOf(address tokenOwner) public view returns (uint balance) {
		return balances[tokenOwner];
	}

	// Returns the amount of tokens approved by the owner that can be transferred to the spender's account
	function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
		return allowed[tokenOwner][spender];
	}
	
	// Controls the receipt of tokens. Works with the TransferFrom function, where the ability to receive funds by the recipient is checked. control.
	function approve(address spender, uint tokens) public returns (bool success) {
		allowed[msg.sender][spender] = tokens;
		emit Approval(msg.sender, spender, tokens);
		return true;
	}

	// Transfer tokens to the investor's account
	function transfer(address to, uint tokens) public returns (bool success) {
		balances[msg.sender] = safeSub(balances[msg.sender], tokens);
		balances[to] = safeAdd(balances[to], tokens);
		emit Transfer(msg.sender, to, tokens);
		return true;
	}
	
	// This function is responsible for making transactions within the system.
	function transferFrom(address from, address to, uint tokens) public returns (bool success) {
		balances[from] = safeSub(balances[from], tokens);
		allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
		balances[to] = safeAdd(balances[to], tokens);
		emit Transfer(from, to, tokens);
		return true;
	}
}