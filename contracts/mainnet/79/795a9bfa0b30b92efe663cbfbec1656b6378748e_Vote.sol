pragma solidity ^0.4.10;
contract ERC20 {
  uint public totalSupply;
  function balanceOf(address who) constant returns (uint);
  function allowance(address owner, address spender) constant returns (uint);

  function transfer(address to, uint value) returns (bool ok);
  function transferFrom(address from, address to, uint value) returns (bool ok);
  function approve(address spender, uint value) returns (bool ok);
  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}
/**
 * Provides methods to safely add, subtract and multiply uint256 numbers.
 */
contract SafeMath {
  uint256 constant private MAX_UINT256 =
    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

  /**
   * Add two uint256 values, throw in case of overflow.
   *
   * @param x first value to add
   * @param y second value to add
   * @return x + y
   */
  function safeAdd (uint256 x, uint256 y)
  constant internal
  returns (uint256 z) {
    if (x > MAX_UINT256 - y) throw;
    return x + y;
  }

  /**
   * Subtract one uint256 value from another, throw in case of underflow.
   *
   * @param x value to subtract from
   * @param y value to subtract
   * @return x - y
   */
  function safeSub (uint256 x, uint256 y)
  constant internal
  returns (uint256 z) {
    if (x < y) throw;
    return x - y;
  }

  /**
   * Multiply two uint256 values, throw in case of overflow.
   *
   * @param x first value to multiply
   * @param y second value to multiply
   * @return x * y
   */
  function safeMul (uint256 x, uint256 y)
  constant internal
  returns (uint256 z) {
    if (y == 0) return 0; // Prevent division by zero at the next line
    if (x > MAX_UINT256 / y) throw;
    return x * y;
  }
}

contract Vote is ERC20, SafeMath{

	mapping (address => uint) balances;
	mapping (address => mapping (address => uint)) allowed;

	uint public totalSupply;
	uint public initialSupply;
	string public name;
	string public symbol;
	uint8 public decimals;

	function Vote(){
		initialSupply = 100000;
		totalSupply = initialSupply;
		balances[msg.sender] = initialSupply;
		name = "EthTaipei Logo Vote";
		symbol = "EthTaipei Logo";
		decimals = 0;
	}

	function transfer(address _to, uint _value) returns (bool) {
	    balances[msg.sender] = safeSub(balances[msg.sender], _value);
	    balances[_to] = safeAdd(balances[_to], _value);
	    Transfer(msg.sender, _to, _value);
	    return true;
  	}

  	function transferFrom(address _from, address _to, uint _value) returns (bool) {
	    var _allowance = allowed[_from][msg.sender];	    
	    balances[_to] = safeAdd(balances[_to], _value);
	    balances[_from] = safeSub(balances[_from], _value);
	    allowed[_from][msg.sender] = safeSub(_allowance, _value);
	    Transfer(_from, _to, _value);
	    return true;
  	}

  	function approve(address _spender, uint _value) returns (bool) {
    	allowed[msg.sender][_spender] = _value;
    	Approval(msg.sender, _spender, _value);
    	return true;
  	}

  	function balanceOf(address _address) constant returns (uint balance) {
  		return balances[_address];
  	}

  	function allowance(address _owner, address _spender) constant returns (uint remaining) {
    	return allowed[_owner][_spender];
  	}

}