pragma solidity ^0.4.11;

contract SafeMath {
  function safeMul(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint256 a, uint256 b) internal returns (uint256) {
    assert(b > 0);
    uint256 c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

  function safeSub(uint256 a, uint256 b) internal returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a + b;
    assert(c>=a && c>=b);
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
  function balanceOf(address who) constant returns (uint256);
  function allowance(address owner, address spender) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool ok);
  function transferFrom(address from, address to, uint256 value) returns (bool ok);
  function approve(address spender, uint256 value) returns (bool ok);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract StandardToken is ERC20, SafeMath {
  mapping(address => uint256) balances;
  mapping (address => mapping (address => uint256)) allowed;
  uint256 public _totalSupply;
  address public _creator;
  bool bIsFreezeAll = false;

  function totalSupply() constant returns (uint256 totalSupply) {
	totalSupply = _totalSupply;
  }

  function transfer(address _to, uint256 _value) returns (bool success) {
    require(bIsFreezeAll == false);
    balances[msg.sender] = safeSub(balances[msg.sender], _value);
    balances[_to] = safeAdd(balances[_to], _value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
    require(bIsFreezeAll == false);
    var _allowance = allowed[_from][msg.sender];
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
	require(bIsFreezeAll == false);
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

  function freezeAll()
  {
	require(msg.sender == _creator);
	bIsFreezeAll = !bIsFreezeAll;
  }
}

contract COINBIG is StandardToken {

  string public name = "COINBIG";
  string public symbol = "CB";
  uint256 public constant decimals = 18;
  uint256 public constant INITIAL_SUPPLY = 10000000000 * 10 ** decimals;	

  
  function COINBIG() {
    _totalSupply = INITIAL_SUPPLY;
	_creator = 0xfCe1155052AF6c8CB04EDA1CeBB390132E2F0012;
	balances[_creator] = INITIAL_SUPPLY;
	bIsFreezeAll = false;
  }
  
  function destroy() {
	require(msg.sender == _creator);
	suicide(_creator);
  }

}