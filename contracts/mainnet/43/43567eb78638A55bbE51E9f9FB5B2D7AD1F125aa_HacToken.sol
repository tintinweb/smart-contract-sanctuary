pragma solidity ^0.4.11;

contract ERC20Interface {
	function totalSupply() constant returns (uint256 total); // Get the total token supply
	function balanceOf(address _owner) constant returns (uint256 balance); // Get the account balance of another account with address _owner
	function transfer(address _to, uint256 _value) returns (bool success); // Send _value amount of tokens to address _to
	function transferFrom(address _from, address _to, uint256 _value) returns (bool success); // Send _value amount of tokens from address _from to address _to
	// Allow _spender to withdraw from your account, multiple times, up to the _value amount.
	// If this function is called again it overwrites the current allowance with _value.
	// this function is required for some DEX functionality
	// function approve(address _spender, uint256 _value) returns (bool success);
	// function allowance(address _owner, address _spender) constant returns (uint256 remaining); // Returns the amount which _spender is still allowed to withdraw from _owner
	event Transfer(address indexed _from, address indexed _to, uint256 _value); // Triggered when tokens are transferred.
	//event Approval(address indexed _owner, address indexed _spender, uint256 _value); // Triggered whenever approve(address _spender, uint256 _value) is called.
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
	function mul(uint256 a, uint256 b) internal constant returns (uint256) {
		uint256 c = a * b;
		assert(a == 0 || c / a == b);
		return c;
	}

	function div(uint256 a, uint256 b) internal constant returns (uint256) {
		// assert(b > 0); // Solidity automatically throws when dividing by 0
		uint256 c = a / b;
		// assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
		return c;
	}

	function sub(uint256 a, uint256 b) internal constant returns (uint256) {
		assert(b <= a);
		return a - b;
	}

	function add(uint256 a, uint256 b) internal constant returns (uint256) {
		uint256 c = a + b;
		assert(c >= a);
		return c;
	}
}

contract owned {
	address public owner;

	function owned() {
		owner = msg.sender;
	}

	modifier onlyOwner {
		if (msg.sender != owner) revert();
		_;
	}

	/* function transferOwnership(address newOwner) onlyOwner {
		owner = newOwner;
	} */
}

contract tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData); }

contract HacToken is ERC20Interface, owned{
	string public standard = &#39;Token 0.1&#39;;
	string public name;
	string public symbol;
	uint8 public decimals;
	uint256 public freeTokens;
	uint256 public totalSupply;

	mapping (address => uint256) public balanceOf;

	event TransferFrom(address indexed _from, address indexed _to, uint256 _value); // Triggered when tokens are transferred by owner.

	function HacToken() {
		totalSupply = freeTokens = 10000000000000;
		name = "HAC Token";
		decimals = 4;
		symbol = "HAC";
	}

	function totalSupply() constant returns (uint256 total) {
		return total = totalSupply;
	}
	function balanceOf(address _owner) constant returns (uint256 balance) {
		return balanceOf[_owner];
	}
	/* function approve(address _spender, uint256 _amount) returns (bool success) {
		return false;
	}
	function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
		return 0;
	} */
	function () {
		revert();
	}

	function setTokens(address target, uint256 amount) onlyOwner {
		if(freeTokens < amount) revert();

		balanceOf[target] = SafeMath.add(balanceOf[target], amount);
		freeTokens = SafeMath.sub(freeTokens, amount);
		Transfer(this, target, amount);
	}

	function transfer(address _to, uint256 _value) returns (bool success){
		balanceOf[msg.sender] = SafeMath.sub(balanceOf[msg.sender], _value);
		balanceOf[_to] = SafeMath.add(balanceOf[_to], _value);

		Transfer(msg.sender, _to, _value);
		return true;
	}

	function transferFrom(address _from, address _to, uint256 _value) onlyOwner returns (bool success) {
		balanceOf[_from] = SafeMath.sub(balanceOf[_from], _value);
		balanceOf[_to] = SafeMath.add(balanceOf[_to], _value);

		TransferFrom(_from, _to, _value);
		return true;
	}
}