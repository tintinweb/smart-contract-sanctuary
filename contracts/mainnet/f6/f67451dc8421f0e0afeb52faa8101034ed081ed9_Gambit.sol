pragma solidity ^0.4.15;

// Abstract contract for the full ERC 20 Token standard
// https://github.com/ethereum/EIPs/issues/20
contract ERC20 {
  // Get the total token supply
  /// @return Total amount of tokens
  function totalSupply() constant returns (uint256);

  // Get the account balance of another account with address _owner
  /// @param _owner The address from which the balance will be retrieved
  /// @return The balance
  function balanceOf(address _owner) constant returns (uint256);

  // Send _value amount of tokens to address _to
  /// @notice send `_value` token to `_to` from `msg.sender`
  /// @param _to The address of the recipient
  /// @param _value The amount of token to be transferred
  /// @return Whether the transfer was successful or not
  function transfer(address _to, uint256 _value) returns (bool);

  // Send _value amount of tokens from address _from to address
  /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
  /// @param _from The address of the sender
  /// @param _to The address of the recipient
  /// @param _value The amount of token to be transferred
  /// @return Whether the transfer was successful or not
  function transferFrom(address _from, address _to, uint256 _value) returns (bool);

  // Allow _spender to withdraw from your account, multiple times, up to the
  // _value amount. If this function is called again it overwrites the current
  // allowance with _value.
  /// @notice `msg.sender` approves `_spender` to spend `_value` tokens
  /// @param _spender The address of the account able to transfer the tokens
  /// @param _value The amount of tokens to be approved for transfer
  /// @return Whether the approval was successful or not
  function approve(address _spender, uint256 _value) returns (bool);

  // Returns the amount which _spender is still allowed to withdraw from _owner
  /// @param _owner The address of the account owning tokens
  /// @param _spender The address of the account able to transfer the tokens
  /// @return Amount of remaining tokens allowed to spent
  function allowance(address _owner, address _spender) constant returns (uint256);

  // Triggered when tokens are transferred.
  event Transfer(address indexed _from, address indexed _to, uint256 _value);

  // Triggered whenever approve(address _spender, uint256 _value) is called.
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

/**
 * Owned
 *
 * Base contract with an owner.
 * Provides onlyOwner modifier, which prevents the function from running if
 * it is called by anyone other than the owner.
 **/
contract Owned {
  address public owner;

  function Owned() {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function changeOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}

contract Token is ERC20 {
  function () {
    // if ether is sent to this address, send it back.
    require(false);
  }

  // Balances for each account
  mapping(address => uint256) balances;

  // Owner of account approves the transfer of an amount to another account
  mapping(address => mapping (address => uint256)) allowed;

  // The total token supply
  uint256 internal _totalSupply;

  // Get the total token supply
  /// @return Total amount of tokens
  function totalSupply() constant returns (uint256) {
    return _totalSupply;
  }

  // Get the account balance of another account with address _owner
  /// @param _owner The address from which the balance will be retrieved
  /// @return The balance
  function balanceOf(address _owner) constant returns (uint256) {
    return balances[_owner];
  }

  // Send _value amount of tokens to address _to
  /// @notice send `_value` token to `_to` from `msg.sender`
  /// @param _to The address of the recipient
  /// @param _value The amount of token to be transferred
  /// @return Whether the transfer was successful or not
  function transfer(address _to, uint256 _value) returns (bool) {
    require(balances[msg.sender] >= _value);
    require(_value > 0);
    require(balances[_to] + _value > balances[_to]);

    balances[msg.sender] -= _value;
    balances[_to]        += _value;
    Transfer(msg.sender, _to, _value);
    return true;
  }

  // Send _value amount of tokens from address _from to address
  /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
  /// @param _from The address of the sender
  /// @param _to The address of the recipient
  /// @param _value The amount of token to be transferred
  /// @return Whether the transfer was successful or not
  function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
    require(balances[_from] >= _value);
    require(_value > 0);
    require(allowed[_from][msg.sender] >= _value);
    require(balances[_to] + _value > balances[_to]);

    balances[_from] -= _value;
    balances[_to]   += _value;
    allowed[_from][msg.sender] -= _value;
    Transfer(_from, _to, _value);
    return true;
  }

  // Allow _spender to withdraw from your account, multiple times, up to the
  // _value amount. If this function is called again it overwrites the current
  // allowance with _value.
  /// @notice `msg.sender` approves `_spender` to spend `_value` tokens
  /// @param _spender The address of the account able to transfer the tokens
  /// @param _value The amount of tokens to be approved for transfer
  /// @return Whether the approval was successful or not
  function approve(address _spender, uint256 _value) returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  // Returns the amount which _spender is still allowed to withdraw from _owner
  /// @param _owner The address of the account owning tokens
  /// @param _spender The address of the account able to transfer the tokens
  /// @return Amount of remaining tokens allowed to spent
  function allowance(address _owner, address _spender) constant returns (uint256) {
    return allowed[_owner][_spender];
  }
}

contract Gambit is Token, Owned {
  string public constant name     = &#39;Gambit&#39;;
  uint8  public constant decimals = 8;
  string public constant symbol   = &#39;GAM&#39;;
  string public constant version  = &#39;1.0.0&#39;;
  uint256 internal _totalBurnt    = 0;

  // Constructor
  function Gambit() {
    _totalSupply = 260000000000000;
    balances[owner] = _totalSupply;
  }

  // Get the total of token burnt
  /// @return Total amount of burned tokens
  function totalBurnt() constant returns (uint256) {
    return _totalBurnt;
  }

  // Only the Owner of the contract can burn tokens.
  /// @param _value The amount of token to be burned
  /// @return Whether the burning was successful or not
  function burn(uint256 _value) onlyOwner returns (bool) {
    require(balances[msg.sender] >= _value);
    require(_value > 0);

    balances[msg.sender] -= _value;
    _totalSupply         -= _value;
    _totalBurnt          += _value;
    Transfer(msg.sender, 0x0, _value);
    return true;
  }
}