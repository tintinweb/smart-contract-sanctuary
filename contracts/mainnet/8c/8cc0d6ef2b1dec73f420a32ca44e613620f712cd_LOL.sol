pragma solidity ^0.4.6;

contract LOL {

  string public name = "LOL Token";
  string public symbol = "LOL";
  uint public decimals = 18;
  uint public INITIAL_SUPPLY = 2000000000000000000000000;

  mapping(address => uint) balances;
  mapping (address => mapping (address => uint)) allowed;
  uint256 public _totalSupply;
  address public _creator;
  bool bIsFreezeAll = false;
  
  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
  
  function safeSub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c>=a && c>=b);
    return c;
  }
  
  function totalSupply() public constant returns (uint256 total) {
	total = _totalSupply;
  }

  function transfer(address _to, uint _value) public returns (bool success) {
    require(bIsFreezeAll == false);
    balances[msg.sender] = safeSub(balances[msg.sender], _value);
    balances[_to] = safeAdd(balances[_to], _value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint _value) public returns (bool success) {
    require(bIsFreezeAll == false);
    var _allowance = allowed[_from][msg.sender];
    balances[_to] = safeAdd(balances[_to], _value);
    balances[_from] = safeSub(balances[_from], _value);
    allowed[_from][msg.sender] = safeSub(_allowance, _value);
    Transfer(_from, _to, _value);
    return true;
  }

  function balanceOf(address _owner) public constant returns (uint balance) {
    return balances[_owner];
  }

  function approve(address _spender, uint _value) public returns (bool success) {
	require(bIsFreezeAll == false);
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) public constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }

  function freezeAll() public 
  {
	require(msg.sender == _creator);
	bIsFreezeAll = !bIsFreezeAll;
  }
  
  function LOL() public {
    _totalSupply = INITIAL_SUPPLY;
	_creator = 0xCEadFdCCd0E8E370D985c49Ed3117b2572243A4a;
	balances[_creator] = INITIAL_SUPPLY;
	bIsFreezeAll = false;
  }
  
  function destroy() public  {
	require(msg.sender == _creator);
	selfdestruct(_creator);
  }

}