pragma solidity ^0.4.11;

library SafeMath {
  function mul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function sub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }

  function assert(bool assertion) internal {
    if (!assertion) {
      throw;
    }
  }
}

contract ShitToken {
  using SafeMath for uint256;

  string public constant name = "Shit";
  string public constant symbol = "SHT";
  uint8 public constant decimals = 18;
  uint256 public totalSupply;
  mapping (address => uint) balances;
  mapping (address => mapping (address => uint)) allowed;
  address crowdsaleWallet;
  address owner;

  // Christmas!
  uint256 saleEndDate = 1498348800;

  // Hopefully this is enough, we might run a second and third sale if not!
  uint256 public beerAndHookersCap = 500000 ether;
  uint256 public shitRate = 419;
  uint256 public totalEtherReceived;
  
  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
  event Created(address indexed donor, uint256 amount, uint256 tokens);

  function () payable {
    require(now < saleEndDate);
    require(msg.value > 0);
    require(totalEtherReceived.add(msg.value) <= beerAndHookersCap);
    uint256 tokens = msg.value.mul(shitRate);
    balances[msg.sender] = balances[msg.sender].add(tokens);
    totalEtherReceived = totalEtherReceived.add(msg.value);
    totalSupply = totalSupply.add(tokens);
    Created(msg.sender, msg.value, tokens);
    crowdsaleWallet.transfer(msg.value);
  }

  function ShitToken(address _crowdsaleWallet) {
    require(_crowdsaleWallet != 0x0);
    owner = msg.sender;
    crowdsaleWallet = _crowdsaleWallet;
  }

  function transfer(address _to, uint _value) returns (bool success) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint _value) returns (bool success) {
    var _allowance = allowed[_from][msg.sender];

    // Check is not needed because safeSub(_allowance, _value) will already throw if this condition is not met
    // if (_value > _allowance) throw;

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  function balanceOf(address _owner) constant returns (uint balance) {
    return balances[_owner];
  }

  function approve(address _spender, uint _value) returns (bool success) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }

  function suicide() {
    require(msg.sender == owner);
    selfdestruct(owner);
  }
}