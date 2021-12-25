/**
 *Submitted for verification at Etherscan.io on 2021-12-25
*/

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


contract PacktToken is IERC20{
	string public name = "Packt ERC20 Token";
	string public symbol = "PET";

	uint256 public totalSupply; // defines the total number of tokens across all address balances
	uint8 public decimals; // will only deal with whole tokens,

	event Transfer(address indexed _from, address indexed _to, uint256 _value); // upon the successful transfer of tokens from one address to another
	event Approval(address indexed _owner, address indexed _spender, uint256 _value);

	mapping (address => uint256) public balances; // only really need a way to store the balance of a given address
	mapping (address => mapping(address => uint256)) public allowed; // but multiple different accounts as delegates
	
	uint256 public totalSupply_ = 100 ether;

	constructor() public {
		balances[msg.sender] = totalSupply_;
		totalSupply = totalSupply_;
		emit Transfer(address(0), msg.sender, totalSupply);
	}

	function totalSupply() public view returns (uint256) {
		return totalSupply_;
	}

	function balanceOf(address tokenOwner) public view returns (uint256) {
		return balances[tokenOwner];
	}

	function transfer(address _to, uint256 _value) public returns (bool success) {
		require(balances[msg.sender] >= _value); // requires that the user making the transfer has a sufficient number of tokens to do so
		balances[msg.sender] -= _value; // The balance of the sender is reduced 
		balances[_to] += _value; // and the balance of the receiver is increased.
		emit Transfer(msg.sender, _to, _value); // The transfer event described earlier must be emitted.
		return true;
	}

	function approve(address _spender, uint256 _value) public returns (bool success) {
		allowed[msg.sender][_spender] = _value;
		emit Approval(msg.sender, _spender, _value);
		return true;
	}

	function allowance(address owner, address delegate) public view returns (uint) {
		return allowed[owner][delegate];
	}

	function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) { // the final piece of the delegated transfer jigsaw
		require(_value <= balances[_from]);
		require(_value <= allowed[_from][msg.sender]);
		balances[_from] -= _value;
		balances[_to] += _value;
		allowed[_from][msg.sender] -= _value;
		emit Transfer(_from, _to, _value);
		return true;
	}
}


/**
* @title SafeMath
* @dev Math operations with safety checks that throw on error
*/
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
	// Gas optimization: this is cheaper than asserting 'a' not beingzero, but the
	// benefit is lost if 'b' is also tested.
	// See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
	if (_a == 0) {
	  return 0;
	}
	c = _a * _b;
	assert(c / _a == _b);
	return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
	// assert(_b > 0); // Solidity automatically throws when dividing by 0
	// uint256 c = _a / _b;
	// assert(_a == _b * c + _a % _b); // There is no case in which this doesn't hold
	return _a / _b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow
  * (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
	assert(_b <= _a);
	return _a - _b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
	c = _a + _b;
	assert(c >= _a);
	return c;
  }
}

contract DEX {

	event Bought(uint256 amount);
	event Sold(uint256 amount);

	IERC20 public token;

	constructor() public {
		token = new PacktToken();
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