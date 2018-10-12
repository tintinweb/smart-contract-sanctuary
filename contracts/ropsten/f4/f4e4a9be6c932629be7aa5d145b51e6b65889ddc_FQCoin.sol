pragma solidity ^0.4.6;


library SafeMathLib {
  function times(uint a, uint b) returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function minus(uint a, uint b) returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function plus(uint a, uint b) returns (uint) {
    uint c = a + b;
    assert(c>=a && c>=b);
    return c;
  }

  function assert(bool assertion) private {
    if (!assertion) throw;
  }
}


library ERC20Lib {
  using SafeMathLib for uint;

  struct TokenStorage {
    mapping (address => uint) balances;
    mapping (address => mapping (address => uint)) allowed;
    uint totalSupply;
  }

  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);

  function init(TokenStorage storage self, uint _initial_supply) {
    self.totalSupply = _initial_supply;
    self.balances[msg.sender] = _initial_supply;
  }

  function transfer(TokenStorage storage self, address _to, uint _value) returns (bool success) {
    self.balances[msg.sender] = self.balances[msg.sender].minus(_value);
    self.balances[_to] = self.balances[_to].plus(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  function transferFrom(TokenStorage storage self, address _from, address _to, uint _value) returns (bool success) {
    var _allowance = self.allowed[_from][msg.sender];

    self.balances[_to] = self.balances[_to].plus(_value);
    self.balances[_from] = self.balances[_from].minus(_value);
    self.allowed[_from][msg.sender] = _allowance.minus(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  function balanceOf(TokenStorage storage self, address _owner) constant returns (uint balance) {
    return self.balances[_owner];
  }

  function approve(TokenStorage storage self, address _spender, uint _value) returns (bool success) {
    self.allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(TokenStorage storage self, address _owner, address _spender) constant returns (uint remaining) {
    return self.allowed[_owner][_spender];
  }
}

/**
 * Standard ERC20 token
 *
 * https://github.com/ethereum/EIPs/issues/20
 * Based on code by FirstBlood:
 * https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */

 contract FQCoin {
   using ERC20Lib for ERC20Lib.TokenStorage;

   ERC20Lib.TokenStorage token;

   string public name = "JOJOCoin";
   string public symbol = "JJC";
   uint public decimals = 18;
   uint public INITIAL_SUPPLY = 10000000000;
   uint256 public totalSupply;

   function FQCoin() {
      totalSupply = INITIAL_SUPPLY * 10 ** uint256(decimals);
     token.init(totalSupply);
   }

   function totalSupply() constant returns (uint) {
     return token.totalSupply;
   }

   function balanceOf(address who) constant returns (uint) {
     return token.balanceOf(who);
   }

   function allowance(address owner, address spender) constant returns (uint) {
     return token.allowance(owner, spender);
   }

   function transfer(address to, uint value) returns (bool ok) {
     return token.transfer(to, value);
   }

   function transferFrom(address from, address to, uint value) returns (bool ok) {
     return token.transferFrom(from, to, value);
   }

   function approve(address spender, uint value) returns (bool ok) {
     return token.approve(spender, value);
   }

   event Transfer(address indexed from, address indexed to, uint value);
   event Approval(address indexed owner, address indexed spender, uint value);
 }