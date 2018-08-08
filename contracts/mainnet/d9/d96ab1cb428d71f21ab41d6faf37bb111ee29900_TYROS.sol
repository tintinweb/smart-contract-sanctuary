pragma solidity ^0.4.24;

contract SafeMath {
  function safeMul(uint256 a, uint256 b) pure internal returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint256 a, uint256 b) pure internal returns (uint256) {
    assert(b > 0);
    uint256 c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

  function safeSub(uint256 a, uint256 b) pure internal returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint256 a, uint256 b) pure internal returns (uint256) {
    uint256 c = a + b;
    assert(c>=a && c>=b);
    return c;
  }

  function max64(uint64 a, uint64 b) pure internal returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) pure internal returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) pure internal returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) pure internal returns (uint256) {
    return a < b ? a : b;
  }
}

contract ERC20 {
  function totalSupply() public view returns (uint256 supply);
  function balanceOf(address who) public view returns (uint256 balance);
  function allowance(address owner, address spender) public view returns (uint256 remaining);
  function transfer(address to, uint256 value) public returns (bool ok);
  function transferFrom(address from, address to, uint256 value) public returns (bool ok);
  function approve(address spender, uint256 value) public returns (bool ok);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract StandardToken is ERC20, SafeMath {
  mapping(address => uint256) balances;
  mapping (address => mapping (address => uint256)) allowed;
  uint256 public _totalSupply;
  address public _creator;
  bool bIsFreezeAll = false;

  function totalSupply() public view returns (uint256) 
  {
    return _totalSupply;
  }

  function balanceOf(address _owner) public view returns (uint256) 
  {
    return balances[_owner];
  }

  function allowance(address _owner, address _spender) public view returns (uint256) 
  {
    return allowed[_owner][_spender];
  }

  function transfer(address _to, uint256 _value) public returns (bool) 
  {
    require(bIsFreezeAll == false);
    balances[msg.sender] = safeSub(balances[msg.sender], _value);
    balances[_to] = safeAdd(balances[_to], _value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) 
  {
    require(bIsFreezeAll == false);
    uint256 _allowance = allowed[_from][msg.sender];
    balances[_to] = safeAdd(balances[_to], _value);
    balances[_from] = safeSub(balances[_from], _value);
    allowed[_from][msg.sender] = safeSub(_allowance, _value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  function approve(address _spender, uint256 _value) public returns (bool) 
  {
	  require(bIsFreezeAll == false);
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  function freezeAll() public
  {
    require(msg.sender == _creator);
    bIsFreezeAll = !bIsFreezeAll;
  }
}

contract TYROS is StandardToken {
  string public name = "TYROS Token";
  string public symbol = "TYROS";
  uint256 public constant decimals = 18;
  uint256 public constant initial_supply = 50 * 10 ** 26;	
  
  mapping (address => string) public keys;

  event LogRegister (address user, string key);

  constructor() public
  {
    _creator = msg.sender;
    _totalSupply = initial_supply;
    balances[_creator] = initial_supply;
    bIsFreezeAll = false;
  }
  
  function destroy() public
  {
    require(msg.sender == _creator);
    selfdestruct(_creator);
  }

  function register(string key) public 
  {
    keys[msg.sender] = key;
    emit LogRegister(msg.sender, key);
  }
}