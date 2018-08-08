pragma solidity ^0.4.16;

library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a / b;
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

contract ERC20 {

    uint256 public totalSupply;

    function balanceOf(address _owner) constant returns (uint256 balance);

    function transfer(address _to, uint256 _value) returns (bool success);

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);

    function approve(address _spender, uint256 _value) returns (bool success);

    function allowance(address _owner, address _spender) constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    event Approval(address indexed _owner, address indexed _spender, uint256  _value);
}


contract TPOMZ is ERC20 {

	using SafeMath for uint256;                                        // Use safe math library

    mapping (address => uint256) balances;                             // Balances table
    mapping (address => mapping (address => uint256)) allowed;         // Allowance table

    uint public constant decimals = 8;                                 // Decimals count
    uint256 public totalSupply = 5000000000 * 10 ** decimals;          // Total supply
	string public constant name = "TPOMZ";                             // Coin name
    string public constant symbol = "TPOMZ";                           // Coin symbol

	function TPOMZ() {                                                 // Constructor
		balances[msg.sender] = totalSupply;                            // Give the creator all initial tokens
	}

    function balanceOf(address _owner) constant public returns (uint256) {
	    return balances[_owner];                                        // Return tokens count from balance table by address
    }

    function transfer(address _to, uint256 _value) returns (bool success) {
        if (balances[msg.sender] >= _value && _value > 0) {             // Check if the sender has enough
            balances[msg.sender] = balances[msg.sender].sub(_value);    // Safe decrease sender balance
            balances[_to] = balances[_to].add(_value);                  // Safe increase recipient balance
            Transfer(msg.sender, _to, _value);                          // Emit transfer event
            return true;
        } else {
            return false;
         }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (balances[_from] >= _value &&                                // Check if the from has enough
            allowed[_from][msg.sender] >= _value && _value > 0) {       // Check allowance table row
			balances[_from] = balances[_from].sub(_value);              // Safe decrease from balance
			allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value); // Safe decrease allowance
			balances[_to] = balances[_to].add(_value);                  // Safe increase recipient balance
            Transfer(_from, _to, _value);                               // Emit transfer event
            return true;
        } else { return false; }
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;                         // Update allowed
        Approval(msg.sender, _spender, _value);                         // Emit approval event
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];                                 // Check allowed
    }

	function () {
        revert();                                                       // If ether is sent to this address, send it back.
    }

}