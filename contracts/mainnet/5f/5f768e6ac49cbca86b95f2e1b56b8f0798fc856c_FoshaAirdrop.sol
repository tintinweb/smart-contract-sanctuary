pragma solidity ^0.4.24;

contract SafeMath {
  uint256 constant private MAX_UINT256 =
    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

  function safeAdd (uint256 x, uint256 y)
  pure internal
  returns (uint256 z) {
    assert (x <= MAX_UINT256 - y);
    return x + y;
  }

  function safeSub (uint256 x, uint256 y)
  pure internal
  returns (uint256 z) {
    assert (x >= y);
    return x - y;
  }

  function safeMul (uint256 x, uint256 y)
  pure internal
  returns (uint256 z) {
    if (y == 0) return 0; // Prevent division by zero at the next line
    assert (x <= MAX_UINT256 / y);
    return x * y;
  }
}

contract Token {

  function totalSupply () public view returns (uint256 supply);

  function balanceOf (address _owner) public view returns (uint256 balance);

  function transfer (address _to, uint256 _value)
  public returns (bool success);

  function transferFrom (address _from, address _to, uint256 _value)
  public returns (bool success);

  function approve (address _spender, uint256 _value)
  public returns (bool success);

  function allowance (address _owner, address _spender)
  public view returns (uint256 remaining);

  event Transfer (address indexed _from, address indexed _to, uint256 _value);

  event Approval (
    address indexed _owner, address indexed _spender, uint256 _value);
}

contract AddressSet {
  function contains (address _address) public view returns (bool);
}

contract AbstractToken is Token, SafeMath {
  function AbstractToken () public {
    // Do nothing
  }

  function balanceOf (address _owner) public view returns (uint256 balance) {
    return accounts [_owner];
  }

  function transfer (address _to, uint256 _value)
  public returns (bool success) {
    uint256 fromBalance = accounts [msg.sender];
    if (fromBalance < _value) return false;
    if (_value > 0 && msg.sender != _to) {
      accounts [msg.sender] = safeSub (fromBalance, _value);
      accounts [_to] = safeAdd (accounts [_to], _value);
    }
    Transfer (msg.sender, _to, _value);
    return true;
  }

  function transferFrom (address _from, address _to, uint256 _value)
  public returns (bool success) {
    uint256 spenderAllowance = allowances [_from][msg.sender];
    if (spenderAllowance < _value) return false;
    uint256 fromBalance = accounts [_from];
    if (fromBalance < _value) return false;

    allowances [_from][msg.sender] =
      safeSub (spenderAllowance, _value);

    if (_value > 0 && _from != _to) {
      accounts [_from] = safeSub (fromBalance, _value);
      accounts [_to] = safeAdd (accounts [_to], _value);
    }
    Transfer (_from, _to, _value);
    return true;
  }

  function approve (address _spender, uint256 _value)
  public returns (bool success) {
    allowances [msg.sender][_spender] = _value;
    Approval (msg.sender, _spender, _value);

    return true;
  }

  function allowance (address _owner, address _spender)
  public view returns (uint256 remaining) {
    return allowances [_owner][_spender];
  }

  mapping (address => uint256) internal accounts;

  mapping (address => mapping (address => uint256)) internal allowances;
}

contract AbstractVirtualToken is AbstractToken {

  uint256 constant MAXIMUM_TOKENS_COUNT =
    0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

  uint256 constant BALANCE_MASK =
    0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

  uint256 constant MATERIALIZED_FLAG_MASK =
    0x8000000000000000000000000000000000000000000000000000000000000000;

  function AbstractVirtualToken () public AbstractToken () {
    // Do nothing
  }

  function totalSupply () public view returns (uint256 supply) {
    return tokensCount;
  }

  function balanceOf (address _owner) public view returns (uint256 balance) {
    return safeAdd (
      accounts [_owner] & BALANCE_MASK, getVirtualBalance (_owner));
  }

  function transfer (address _to, uint256 _value)
  public returns (bool success) {
    if (_value > balanceOf (msg.sender)) return false;
    else {
      materializeBalanceIfNeeded (msg.sender, _value);
      return AbstractToken.transfer (_to, _value);
    }
  }

  function transferFrom (address _from, address _to, uint256 _value)
  public returns (bool success) {
    if (_value > allowance (_from, msg.sender)) return false;
    if (_value > balanceOf (_from)) return false;
    else {
      materializeBalanceIfNeeded (_from, _value);
      return AbstractToken.transferFrom (_from, _to, _value);
    }
  }

  function virtualBalanceOf (address _owner)
  internal view returns (uint256 _virtualBalance);

  function getVirtualBalance (address _owner)
  private view returns (uint256 _virtualBalance) {
    if (accounts [_owner] & MATERIALIZED_FLAG_MASK != 0) return 0;
    else {
      _virtualBalance = virtualBalanceOf (_owner);
      uint256 maxVirtualBalance = safeSub (MAXIMUM_TOKENS_COUNT, tokensCount);
      if (_virtualBalance > maxVirtualBalance)
        _virtualBalance = maxVirtualBalance;
    }
  }

  function materializeBalanceIfNeeded (address _owner, uint256 _value) private {
    uint256 storedBalance = accounts [_owner];
    if (storedBalance & MATERIALIZED_FLAG_MASK == 0) {
      // Virtual balance is not materialized yet
      if (_value > storedBalance) {
        // Real balance is not enough
        uint256 virtualBalance = getVirtualBalance (_owner);
        require (safeSub (_value, storedBalance) <= virtualBalance);
        accounts [_owner] = MATERIALIZED_FLAG_MASK |
          safeAdd (storedBalance, virtualBalance);
        tokensCount = safeAdd (tokensCount, virtualBalance);
      }
    }
  }

  uint256 internal tokensCount;
}

contract FoshaAirdrop is AbstractVirtualToken {

  uint256 private constant VIRTUAL_THRESHOLD = 0.1 ether;

  uint256 private constant VIRTUAL_COUNT = 10e8;

  function FoshaAirdrop () AbstractVirtualToken () {
    owner = msg.sender;
  }

  function name () constant returns (string result) {
    return "Fosha Airdrop";
  }

  function symbol () constant returns (string result) {
    return "FOSHAIR";
  }

  function decimals () constant returns (uint8 result) {
    return 8;
  }

  function massNotify (address [] _owners) {
    require (msg.sender == owner);
    uint256 count = _owners.length;
    for (uint256 i = 0; i < count; i++)
      Transfer (address (0), _owners [i], VIRTUAL_COUNT);
  }

  function kill () {
    require (msg.sender == owner);
    selfdestruct (owner);
  }

  function virtualBalanceOf (address _owner)
  internal constant returns (uint256 _virtualBalance) {
    return _owner.balance >= VIRTUAL_THRESHOLD ? VIRTUAL_COUNT : 0;
  }

  address private owner;
}