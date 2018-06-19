pragma solidity ^0.4.11;

/**
 * Math operations with safety checks
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }

}

contract ERC20 {
      function totalSupply() constant returns (uint256 totalSupply);
      function balanceOf(address _owner) constant returns (uint balance);
      function transfer(address _to, uint _value) returns (bool success);
      function transferFrom(address _from, address _to, uint _value) returns (bool success);
      function approve(address _spender, uint _value) returns (bool success);
      function allowance(address _owner, address _spender) constant returns (uint remaining);
     event Transfer(address indexed _from, address indexed _to, uint256 _value);
     event Approval(address indexed _owner, address indexed _spender, uint256 _value);
 }

contract OGR is ERC20 {
    
       using SafeMath for uint256;
       
       uint public _totalSupply = 0;
       
       bool public executed = false;
       
       address public owner;
       string public symbol;
       string public name;
       uint8 public decimals;
       uint256 public unitsOneEthCanBuy;
       
       mapping(address => uint256) balances;
       mapping(address => mapping(address => uint256)) allowed;
       
       function () payable {
           createTokens();
       }
       
       function ICO (string _symbol, string _name, uint8 _decimals, uint256 _unitsOneEthCanBuy) {
           owner = msg.sender;
           symbol = _symbol;
           name = _name;
           decimals = _decimals;
           unitsOneEthCanBuy = _unitsOneEthCanBuy;
       }
       
       function createTokens() payable {
           require(msg.value > 0);
           uint256 tokens = msg.value.mul(unitsOneEthCanBuy);
           _totalSupply = _totalSupply.add(tokens);
           balances[msg.sender] = balances[msg.sender].add(tokens);
           owner.transfer(msg.value);
		   executed = true;
       }
       
       function totalSupply() constant returns (uint256) {
           return _totalSupply;
       }
       
       function balanceOf (address _owner) constant returns (uint256) {
           return balances[_owner];
       }
       
       function transfer(address _to, uint256 _value) returns (bool) {
           require(balances[msg.sender] >= _value && _value > 0);
           balances[msg.sender] = balances[msg.sender].sub(_value);
           balances[_to] = balances[_to].add(_value);
           Transfer(msg.sender, _to, _value);
           return true;
       }
       
       function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
           require (allowed[_from][msg.sender] >= _value && balances[_from] >= _value && _value > 0);
           balances[_from] = balances[_from].sub(_value);
           balances[_to] = balances[_to].add(_value);
           allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
           Transfer(_from, _to, _value);
           return true;
       }
       
       function approve (address _spender, uint256 _value) returns (bool) {
           allowed[msg.sender][_spender] = _value;
           Approval(msg.sender, _spender, _value);
           return true;
       }
       
       function allowance(address _owner, address _spender) constant returns (uint256) {
           return allowed[_owner][_spender];
       }
       
       event Transfer(address indexed _from, address indexed _to, uint256 _value);
       event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}