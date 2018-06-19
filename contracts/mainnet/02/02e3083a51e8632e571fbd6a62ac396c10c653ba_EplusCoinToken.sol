pragma solidity ^0.4.8;

contract SafeMath {
  function safeMul(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint256 a, uint256 b) internal returns (uint256) {
    assert(b &gt; 0);
    uint256 c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

  function safeSub(uint256 a, uint256 b) internal returns (uint256) {
    assert(b &lt;= a);
    return a - b;
  }

  function safeAdd(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a + b;
    assert(c&gt;=a &amp;&amp; c&gt;=b);
    return c;
  }

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a &gt;= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a &lt; b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a &gt;= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a &lt; b ? a : b;
  }

  function assert(bool assertion) internal {
    if (!assertion) {
      throw;
    }
  }
}

contract ERC20 {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function allowance(address owner, address spender) constant returns (uint256);

  function transfer(address to, uint256 value) returns (bool ok);
  function transferFrom(address from, address to, uint256 value) returns (bool ok);
  function approve(address spender, uint256 value) returns (bool ok);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract StandardToken is ERC20, SafeMath {

  mapping(address =&gt; uint256) balances;
  mapping (address =&gt; mapping (address =&gt; uint256)) allowed;

  function transfer(address _to, uint256 _value) returns (bool success) {
    balances[msg.sender] = safeSub(balances[msg.sender], _value);
    balances[_to] = safeAdd(balances[_to], _value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
    var _allowance = allowed[_from][msg.sender];

    // Check is not needed because safeSub(_allowance, _value) will already throw if this condition is not met
    // if (_value &gt; _allowance) throw;

    balances[_to] = safeAdd(balances[_to], _value);
    balances[_from] = safeSub(balances[_from], _value);
    allowed[_from][msg.sender] = safeSub(_allowance, _value);
    Transfer(_from, _to, _value);
    return true;
  }

  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

  function approve(address _spender, uint256 _value) returns (bool success) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}

/// @title EplusCoin Token
contract EplusCoinToken is StandardToken {

    string public name = &quot;EplusCoin&quot;;          // name of the token
    string public symbol = &quot;EPLUS&quot;;
    uint256 public decimals = 8;                  // token has 8 digit precision
    string public version = &#39;H0.1&#39;;

    uint256 public totalSupply = 16800000000000000;  // total supply of 168 Million Tokens

    /// @notice Initializes the contract and allocates all initial tokens to the owner
    function EplusCoinToken() {
        balances[msg.sender] = totalSupply;
    }
}