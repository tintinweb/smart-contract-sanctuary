pragma solidity ^0.4.11;
/* 2017-07-07 - A man can be destroyed but not defeated - Discrash Limited Liability Company */


library SafeMath {
  function add(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

  function sub(uint256 a, uint256 b) internal returns (uint256) {
    assert(b <= a);
    return a - b;
  }
}


contract ERC20Basic {
  uint256 public totalSupply;

  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value);

  event Transfer(address indexed from, address indexed to, uint256 value);
}


contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value);
  function approve(address spender, uint256 value);

  event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  function transfer(address _to, uint256 _value) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
  }

  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }
}


contract StandardToken is ERC20, BasicToken {
  mapping (address => mapping (address => uint256)) allowed;

  function transferFrom(address _from, address _to, uint256 _value) {
    var _allowance = allowed[_from][msg.sender];

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
  }

  function approve(address _spender, uint256 _value) {
    if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) throw;

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
  }

  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }
}


contract DiscrashCredit is StandardToken {
  string public name = "DiscrashCredit";
  string public symbol = "DCC";
  uint256 public decimals = 18;
  uint256 public initialSupply = 7 * 10**9 * 10**18;

  function DiscrashCredit() {
    totalSupply = initialSupply;
    balances[msg.sender] = initialSupply;
  }
}