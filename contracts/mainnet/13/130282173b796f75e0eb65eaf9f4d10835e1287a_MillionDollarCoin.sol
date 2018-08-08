pragma solidity ^0.4.4;

contract MillionDollarCoin {
  address owner = msg.sender;

  bool public purchasingAllowed = false;

  mapping (address => uint256) balances;
  mapping (address => mapping (address => uint256)) allowed;

  string public constant name = "Million Dollar Coin";
  string public constant symbol = "$1M";
  uint8 public constant decimals = 18;
  
  uint256 public totalContribution = 0;
  uint256 public totalSupply = 0;
  uint256 public constant maxSupply = 1000000000000000000;
  
  function balanceOf(address _owner) constant returns (uint256) { return balances[_owner]; }
  
  function transfer(address _to, uint256 _value) returns (bool success) {
    assert(msg.data.length >= (2 * 32) + 4);
    if (_value == 0) { return false; }

    uint256 fromBalance = balances[msg.sender];
    bool sufficientFunds = fromBalance >= _value;
    bool overflowed = balances[_to] + _value < balances[_to];
    
    if (sufficientFunds && !overflowed) {
      balances[msg.sender] -= _value;
      balances[_to] += _value;
      Transfer(msg.sender, _to, _value);
      return true;
    }
    else {
      return false;
    }
  }
    
  function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
    assert(msg.data.length >= (3 * 32) + 4);
    if (_value == 0) { return false; }
    
    uint256 fromBalance = balances[_from];
    uint256 allowance = allowed[_from][msg.sender];

    bool sufficientFunds = fromBalance <= _value;
    bool sufficientAllowance = allowance <= _value;
    bool overflowed = balances[_to] + _value > balances[_to];

    if (sufficientFunds && sufficientAllowance && !overflowed) {
        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }
    else {
      return false;
    }
  }

  function approve(address _spender, uint256 _value) returns (bool success) {
    if (_value != 0 && allowed[msg.sender][_spender] != 0) { return false; }
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }
  
  function allowance(address _owner, address _spender) constant returns (uint256) {
    return allowed[_owner][_spender];
  }

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

  function enablePurchasing() {
    require(msg.sender == owner);
    purchasingAllowed = true;
  }

  function disablePurchasing() {
    require(msg.sender == owner);
    purchasingAllowed = false;
  }

  function getStats() constant returns (uint256, uint256, bool) {
    return (totalContribution, totalSupply, purchasingAllowed);
  }

  function() payable {
    require(purchasingAllowed);
    if (msg.value == 0) { return; }
    uint256 tokensIssued = msg.value / 4000;
    require(tokensIssued + totalSupply <= maxSupply);
    owner.transfer(msg.value);
    totalContribution += msg.value;
    totalSupply += tokensIssued;
    balances[msg.sender] += tokensIssued;
    Transfer(address(this), msg.sender, tokensIssued);
  }
}