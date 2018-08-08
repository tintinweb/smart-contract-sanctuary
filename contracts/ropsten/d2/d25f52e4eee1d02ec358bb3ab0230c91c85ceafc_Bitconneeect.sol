pragma solidity ^0.4.24;

/*
 Author: vkoskiv
 Bitconnect 2.0
 Changes:
 
 Expose total supply as a function
 Introduce a selfdestruct
 */

// ERC Token Standard 20 Interface
interface ERC20 {
	// Get the total token supply
	function totalSupply() external constant returns (uint256);
	// Get the account balance of another account with address _owner
	function balanceOf(address _owner) external constant returns (uint256);
	// Send _value amount of tokens to address _to
	function transfer(address _to, uint _value) external returns (bool success);
	// Send _value amount of tokens from address _from to address _to
	function transferFrom(address _from, address _to, uint _value) external returns (bool success);
	// Allow _spender to withdraw from your account, multiple times, up to the _value amount.
	// If this function is called again it overwrites the current allowance with _value.
	// this function is required for some DEX functionality
	function approve(address _spender, uint _value) external returns (bool success);
	// Returns the amount which _spender is still allowed to withdraw from _owner
	function allowance(address _owner, address _spender) external constant returns (uint256 remaining);
	// Triggered when tokens are transferred.
	event Transfer(address indexed _from, address indexed _to, uint _value);
	// Triggered whenever approve(address _spender, uint256 _value) is called.
	event Approval(address indexed _owner, address indexed _spender, uint _value);
}

contract Bitconneeect is ERC20 {
	
	//Token params
	string public constant name = "BitConnect 2.0";
	string public constant symbol = "BTX";
	uint8 public constant decimals = 18;
	//Keep track of current supply
	uint256 public _totalSupply = 10000;
	
	//The conversion rate. 1ETH gets you 1000 BTX
	uint256 public constant RATE = 1000;
	
	using SafeMath for uint256;
	address public owner;
	
	modifier onlyOwner() {
		if (msg.sender != owner) {
			revert();
		}
		_;
	}
	
	//Map addresses to token balance belonging to those addresses
	mapping(address => uint256) balances;
	//Map addresses with allowances on other addresses
	mapping(address => mapping(address => uint256)) allowed;
	
	//Contract constructor
	constructor() public {
		owner = msg.sender;
		
		//All initial supply to owner
		balances[msg.sender] = _totalSupply;
	}
	
	function totalSupply() public constant returns(uint256) {
		return _totalSupply;
	}
	
	function balanceOf(address _owner) public constant returns(uint256) {
		return balances[_owner];
	}
	
	//Transfer tokens
	function transfer(address _to, uint256 _value) public returns (bool success) {
		_transfer(msg.sender, _to, _value);
		return true;
	}
	
	//Transfer tokens from other addresses
	function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
		//verify allowance
		require(_value <= allowed[_from][msg.sender]);
		allowed[_from][msg.sender] -= _value;
		_transfer(_from, _to, _value);
		return true;
	}
	
	//Approve an allowance for another address
	function approve(address _spender, uint256 _value) public returns (bool success) {
		allowed[msg.sender][_spender] = _value;
		emit Approval(msg.sender, _spender, _value);
		return true;
	}
	
	function allowance(address _owner, address _spender) constant public returns(uint256) {
		return allowed[_owner][_spender];
	}
	
	function selfDestruct(address target) onlyOwner public {
		selfdestruct(target);
	}
	
	//Internal funcs
	
	//Internal transfer
	function _transfer(address sender, address recipient, uint256 amount) internal {
		
		//Make sure recipient isn&#39;t 0x0 address, use burn() instead
		require(recipient != 0x0);
		
		//Make sure sender has enough funds to complete this txn
		require(balances[sender] >= amount);
		
		//Check for overflow
		require(balances[recipient] + amount >= balances[recipient]);
		
		//Update balances
		balances[sender] = balances[sender].sub(amount);
		balances[recipient] = balances[recipient].add(amount);
		
		//Send an event notification to wallets
		emit Transfer(sender, recipient, amount);
	}
	
	//Token events
	//Tokens were transferred
	event Transfer(address indexed _from, address indexed _to, uint256 _value);
	//Approval received
	event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

library SafeMath {
	function mul(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a * b;
		assert(a == 0 || c / a == b);
		return c;
	}
	
	function div(uint256 a, uint256 b) internal pure returns (uint256) {
		assert(b > 0); // Solidity automatically throws when dividing by 0
		uint256 c = a / b;
		assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
		return c;
	}
	
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