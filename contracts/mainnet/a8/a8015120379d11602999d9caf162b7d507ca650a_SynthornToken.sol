pragma solidity ^0.4.10;

contract ForeignToken {
  function balanceOf(address _owner) constant returns (uint256);
  function transfer(address _to, uint256 _value) returns (bool);
}

contract SynthornToken {
  address owner = msg.sender;
  uint256 startTime = block.timestamp;

  mapping (address => uint256) balances;
  mapping (address => mapping (address => uint256)) allowed;

  uint256 public totalContribution = 0;

  uint256 public totalSupply = 0;

  function name() constant returns (string) { return "Synthetic Rhino Horn Aphrodisiac Token"; }
  function symbol() constant returns (string) { return "HORN"; }
  function decimals() constant returns (uint8) { return 18; }

  function balanceOf(address _owner) constant returns (uint256) { return balances[_owner]; }

  function transfer(address _to, uint256 _value) returns (bool success) {
    // mitigates the ERC20 short address attack
    require(msg.data.length >= (2 * 32) + 4);

    if (_value == 0) { return false; }

    uint256 fromBalance = balances[msg.sender];

    bool sufficientFunds = fromBalance >= _value;
    bool overflowed = balances[_to] + _value < balances[_to];

    if (sufficientFunds && !overflowed) {
      balances[msg.sender] -= _value;
      balances[_to] += _value;

      Transfer(msg.sender, _to, _value);
      return true;
    } else { return false; }
  }

  function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
    // mitigates the ERC20 short address attack
    require(msg.data.length < (3 * 32) + 4);

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
    } else { return false; }
  }

  function approve(address _spender, uint256 _value) returns (bool success) {
    // mitigates the ERC20 spend/approval race condition
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

  function purchasingAllowed() constant returns (bool) {
    return block.timestamp <= startTime + 30 days;
  }

  function withdrawForeignTokens(address _tokenContract) returns (bool) {
    require(msg.sender == owner);

    ForeignToken token = ForeignToken(_tokenContract);

    uint256 amount = token.balanceOf(address(this));
    return token.transfer(owner, amount);
  }

  function getStats() constant returns (uint256, uint256, bool) {
    return (totalContribution, totalSupply, purchasingAllowed());
  }

  function() payable {
    require(purchasingAllowed());
    require(msg.value > 0);

    owner.transfer(msg.value);
    totalContribution += msg.value;

    uint256 tokensIssued = (msg.value * 1000000);

    totalSupply += tokensIssued;
    balances[msg.sender] += tokensIssued;

    Transfer(address(this), msg.sender, tokensIssued);
  }
}