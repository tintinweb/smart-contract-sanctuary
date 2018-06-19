pragma solidity ^0.4.10;

contract tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData); }

/// @title ICONOMI Daa token
contract DaaToken {
  //
  // events
  //
  // ERC20 events
  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

  // mint/burn events
  event Mint(address indexed _to, uint256 _amount, uint256 _newTotalSupply);
  event Burn(address indexed _from, uint256 _amount, uint256 _newTotalSupply);

  // admin events
  event BlockLockSet(uint256 _value);
  event NewOwner(address _newOwner);
  event NewMinter(address _minter);

  modifier onlyOwner {
    if (msg.sender == owner) {
      _;
    }
  }

  modifier minterOrOwner {
    if (msg.sender == minter || msg.sender == owner) {
      _;
    }
  }

  modifier blockLock(address _sender) {
    if (!isLocked() || _sender == owner) {
      _;
    }
  }

  modifier validTransfer(address _from, address _to, uint256 _amount) {
    if (isTransferValid(_from, _to, _amount)) {
      _;
    }
  }

  uint256 public totalSupply;
  string public name;
  uint8 public decimals;
  string public symbol;
  string public version = &#39;0.0.1&#39;;
  address public owner;
  address public minter;
  uint256 public lockedUntilBlock;

  function DaaToken(
      string _tokenName,
      uint8 _decimalUnits,
      string _tokenSymbol,
      uint256 _lockedUntilBlock
  ) {

    name = _tokenName;
    decimals = _decimalUnits;
    symbol = _tokenSymbol;
    lockedUntilBlock = _lockedUntilBlock;
    owner = msg.sender;
  }

  function transfer(address _to, uint256 _value)
      public
      blockLock(msg.sender)
      validTransfer(msg.sender, _to, _value)
      returns (bool success)
  {

    // transfer tokens
    balances[msg.sender] -= _value;
    balances[_to] += _value;

    Transfer(msg.sender, _to, _value);
    return true;
  }

  function approve(address _spender, uint256 _value)
      public
      returns (bool success)
  {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint256 _value)
      public
      blockLock(_from)
      validTransfer(_from, _to, _value)
      returns (bool success)
  {

    // check sufficient allowance
    if (_value > allowed[_from][msg.sender]) {
      return false;
    }

    // transfer tokens
    balances[_from] -= _value;
    balances[_to] += _value;
    allowed[_from][msg.sender] -= _value;

    Transfer(_from, _to, _value);
    return true;
  }

  function approveAndCall(address _spender, uint256 _value, bytes _extraData)
      public
      returns (bool success)
  {
    if (approve(_spender, _value)) {
      tokenRecipient(_spender).receiveApproval(msg.sender, _value, this, _extraData);
      return true;
    }
  }

  /// @notice Mint new tokens. Can only be called by minter or owner
  function mint(address _to, uint256 _value)
      public
      minterOrOwner
      blockLock(msg.sender)
      returns (bool success)
  {
    // ensure _value is greater than zero and
    // doesn&#39;t overflow
    if (totalSupply + _value <= totalSupply) {
      return false;
    }

    balances[_to] += _value;
    totalSupply += _value;

    Mint(_to, _value, totalSupply);
    Transfer(0x0, _to, _value);

    return true;
  }

  /// @notice Burn tokens. Can be called by any account
  function burn(uint256 _value)
      public
      blockLock(msg.sender)
      returns (bool success)
  {
    if (_value == 0 || _value > balances[msg.sender]) {
      return false;
    }

    balances[msg.sender] -= _value;
    totalSupply -= _value;

    Burn(msg.sender, _value, totalSupply);
    Transfer(msg.sender, 0x0, _value);

    return true;
  }

  /// @notice Set block lock. Until that block (exclusive) transfers are disallowed
  function setBlockLock(uint256 _lockedUntilBlock)
      public
      onlyOwner
      returns (bool success)
  {
    lockedUntilBlock = _lockedUntilBlock;
    BlockLockSet(_lockedUntilBlock);
    return true;
  }

  /// @notice Replace current owner with new one
  function replaceOwner(address _newOwner)
      public
      onlyOwner
      returns (bool success)
  {
    owner = _newOwner;
    NewOwner(_newOwner);
    return true;
  }

  /// @notice Set account that can mint new tokens
  function setMinter(address _newMinter)
      public
      onlyOwner
      returns (bool success)
  {
    minter = _newMinter;
    NewMinter(_newMinter);
    return true;
  }

  function balanceOf(address _owner)
      public
      constant
      returns (uint256 balance)
  {
    return balances[_owner];
  }

  function allowance(address _owner, address _spender)
      public
      constant
      returns (uint256 remaining)
  {
    return allowed[_owner][_spender];
  }

  /// @notice Are transfers currently disallowed
  function isLocked()
      public
      constant
      returns (bool success)
  {
    return lockedUntilBlock > block.number;
  }

  /// @dev Checks if transfer parameters are valid
  function isTransferValid(address _from, address _to, uint256 _amount)
      private
      constant
      returns (bool isValid)
  {
    return  balances[_from] >= _amount &&  // sufficient balance
            _amount > 0 &&                 // amount is positive
            _to != address(this) &&        // prevent sending tokens to contract
            _to != 0x0                     // prevent sending token to 0x0 address
    ;
  }

  mapping (address => uint256) balances;
  mapping (address => mapping (address => uint256)) allowed;
}