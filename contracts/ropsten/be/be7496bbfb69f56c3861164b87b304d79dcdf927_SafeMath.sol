/**
 *Submitted for verification at Etherscan.io on 2021-12-25
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.4.23;

interface IERC20 {

	function totalSupply() external view returns (uint256);
	function balanceOf(address account) external view returns (uint256);
	function allowance(address owner, address spender) external view returns (uint256);

	function transfer(address recipient, uint256 amount) external returns (bool);
	function approve(address spender, uint256 amount) external returns (bool);
	function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract ERC20Basic is IERC20 {

	string public name = "Cors Token";
	string public symbol = "CORS";
	string public standard = "Cors Token v1.0.0";
	uint8 public decimals = 18;

	event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
	event Transfer(address indexed from, address indexed to, uint tokens);

	mapping(address => uint256) balances;
	mapping(address => mapping (address => uint256)) allowed;

	 uint256 public totalSupply_ = 100 ether;

	using SafeMath for uint256;

	 constructor () public {
		balances[msg.sender] = totalSupply_;
	 }

	function totalSupply() public view returns (uint256) {
		return totalSupply_;
	}

	function balanceOf(address tokenOwner) public view returns (uint256) {
		return balances[tokenOwner];
	}

	function transfer(address receiver, uint256 numTokens) public returns (bool) {
		require(numTokens <= balances[msg.sender]);
		balances[msg.sender] = balances[msg.sender].sub(numTokens);
		balances[receiver] = balances[receiver].add(numTokens);
		emit Transfer(msg.sender, receiver, numTokens);
		return true;
	}

	function approve(address delegate, uint256 numTokens) public returns (bool) {
		allowed[msg.sender][delegate] = numTokens;
		emit Approval(msg.sender, delegate, numTokens);
		return true;
	}

	function allowance(address owner, address delegate) public view returns (uint) {
		return allowed[owner][delegate];
	}

	function transferFrom(address owner, address buyer, uint256 numTokens) public returns (bool) {
		require(numTokens <= balances[owner]);
		require(numTokens <= allowed[owner][msg.sender]);

		balances[owner] = balances[owner].sub(numTokens);
		allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
		balances[buyer] = balances[buyer].add(numTokens);
		emit Transfer(owner, buyer, numTokens);
		return true;
	}
}


library SafeMath {

	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
		assert(b <= a);
		return a - b;
	}

	function add(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a + b;
		assert(c >= a);
		return c;
	}
}


contract DEX {

	event Bought(uint256 amount);
	event Sold(uint256 amount);

	IERC20 public token;

	constructor() public {
		token = new ERC20Basic();
	}

	function buy() payable public {
		uint256 amountTobuy = msg.value;
		uint256 dexBalance = token.balanceOf(address(this));
		require(amountTobuy > 0, "You need to send some ether");
		require(amountTobuy <= dexBalance, "Not enough tokens in the reserve");
		token.transfer(msg.sender, amountTobuy);
		emit Bought(amountTobuy);
	}

	function sell(uint256 amount) public {
		require(amount > 0, "You need to sell at least some tokens");
		uint256 allowance = token.allowance(msg.sender, address(this));
		require(allowance >= amount, "Check the token allowance");
		token.transferFrom(msg.sender, address(this), amount);
		msg.sender.transfer(amount);
		emit Sold(amount);
	}
}