/*
 * Giga Watt Token Smart Contract.  Copyright &#169; 2016 by ABDK Consulting.
 * Author: Mikhail Vladimirov <<span class="__cf_email__" data-cfemail="305d595b5851595c1e465c5154595d59425f4670575d51595c1e535f5d">[email&#160;protected]</span>>
 */
pragma solidity ^0.4.1;

/**
 * ERC-20 standard token interface, as defined
 * <a href="http://github.com/ethereum/EIPs/issues/20">here</a>.
 */
contract Token {
  /**
   * Get total number of tokens in circulation.
   *
   * @return total number of tokens in circulation
   */
  function totalSupply () constant returns (uint256 supply);

  /**
   * Get number of tokens currently belonging to given owner.
   *
   * @param _owner address to get number of tokens currently belonging to the
            owner of
   * @return number of tokens currently belonging to the owner of given address
   */
  function balanceOf (address _owner) constant returns (uint256 balance);

  /**
   * Transfer given number of tokens from message sender to given recipient.
   *
   * @param _to address to transfer tokens from the owner of
   * @param _value number of tokens to transfer to the owner of given address
   * @return true if tokens were transferred successfully, false otherwise
   */
  function transfer (address _to, uint256 _value) returns (bool success);

  /**
   * Transfer given number of tokens from given owner to given recipient.
   *
   * @param _from address to transfer tokens from the owner of
   * @param _to address to transfer tokens to the owner of
   * @param _value number of tokens to transfer from given owner to given
            recipient
   * @return true if tokens were transferred successfully, false otherwise
   */
  function transferFrom (address _from, address _to, uint256 _value)
  returns (bool success);

  /**
   * Allow given spender to transfer given number of tokens from message sender.
   *
   * @param _spender address to allow the owner of to transfer tokens from
            message sender
   * @param _value number of tokens to allow to transfer
   * @return true if token transfer was successfully approved, false otherwise
   */
  function approve (address _spender, uint256 _value) returns (bool success);

  /**
   * Tell how many tokens given spender is currently allowed to transfer from
   * given owner.
   *
   * @param _owner address to get number of tokens allowed to be transferred
   *        from the owner of
   * @param _spender address to get number of tokens allowed to be transferred
   *        by the owner of
   * @return number of tokens given spender is currently allowed to transfer
   *         from given owner
   */
  function allowance (address _owner, address _spender)
  constant returns (uint256 remaining);

  /**
   * Logged when tokens were transferred from one owner to another.
   *
   * @param _from address of the owner, tokens were transferred from
   * @param _to address of the owner, tokens were transferred to
   * @param _value number of tokens transferred
   */
  event Transfer (address indexed _from, address indexed _to, uint256 _value);

  /**
   * Logged when owner approved his tokens to be transferred by some spender.
   *
   * @param _owner owner who approved his tokens to be transferred
   * @param _spender spender who were allowed to transfer the tokens belonging
   *        to the owner
   * @param _value number of tokens belonging to the owner, approved to be
   *        transferred by the spender
   */
  event Approval (
    address indexed _owner, address indexed _spender, uint256 _value);
}

/**
 * Provides methods to safely add, subtract and multiply uint256 numbers.
 */
contract SafeMath {
  uint256 constant private MAX_UINT256 =
    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

  /**
   * Add two uint256 values, throw in case of overflow.
   *
   * @param x first value to add
   * @param y second value to add
   * @return x + y
   */
  function safeAdd (uint256 x, uint256 y)
  constant internal
  returns (uint256 z) {
    if (x > MAX_UINT256 - y) throw;
    return x + y;
  }

  /**
   * Subtract one uint256 value from another, throw in case of underflow.
   *
   * @param x value to subtract from
   * @param y value to subtract
   * @return x - y
   */
  function safeSub (uint256 x, uint256 y)
  constant internal
  returns (uint256 z) {
    if (x < y) throw;
    return x - y;
  }

  /**
   * Multiply two uint256 values, throw in case of overflow.
   *
   * @param x first value to multiply
   * @param y second value to multiply
   * @return x * y
   */
  function safeMul (uint256 x, uint256 y)
  constant internal
  returns (uint256 z) {
    if (y == 0) return 0; // Prevent division by zero at the next line
    if (x > MAX_UINT256 / y) throw;
    return x * y;
  }
}

/**
 * Abstract base contract for contracts implementing Token interface.
 */
contract AbstractToken is Token, SafeMath {
  /**
   * Get total number of tokens in circulation.
   *
   * @return total number of tokens in circulation
   */
  function totalSupply () constant returns (uint256 supply) {
    return tokensCount;
  }

  /**
   * Get number of tokens currently belonging to given owner.
   *
   * @param _owner address to get number of tokens currently belonging to the
            owner of
   * @return number of tokens currently belonging to the owner of given address
   */
  function balanceOf (address _owner) constant returns (uint256 balance) {
    return accounts [_owner];
  }

  /**
   * Transfer given number of tokens from message sender to given recipient.
   *
   * @param _to address to transfer tokens from the owner of
   * @param _value number of tokens to transfer to the owner of given address
   * @return true if tokens were transferred successfully, false otherwise
   */
  function transfer (address _to, uint256 _value) returns (bool success) {
    return doTransfer (msg.sender, _to, _value);
  }

  /**
   * Transfer given number of tokens from given owner to given recipient.
   *
   * @param _from address to transfer tokens from the owner of
   * @param _to address to transfer tokens to the owner of
   * @param _value number of tokens to transfer from given owner to given
            recipient
   * @return true if tokens were transferred successfully, false otherwise
   */
  function transferFrom (address _from, address _to, uint256 _value)
  returns (bool success)
  {
    if (_value > approved [_from][msg.sender]) return false;
    if (doTransfer (_from, _to, _value)) {
      approved [_from][msg.sender] =
        safeSub (approved[_from][msg.sender], _value);
      return true;
    } else return false;
  }

  /**
   * Allow given spender to transfer given number of tokens from message sender.
   *
   * @param _spender address to allow the owner of to transfer tokens from
            message sender
   * @param _value number of tokens to allow to transfer
   * @return true if token transfer was successfully approved, false otherwise
   */
  function approve (address _spender, uint256 _value) returns (bool success) {
    approved [msg.sender][_spender] = _value;
    Approval (msg.sender, _spender, _value);
    return true;
  }

  /**
   * Tell how many tokens given spender is currently allowed to transfer from
   * given owner.
   *
   * @param _owner address to get number of tokens allowed to be transferred
   *        from the owner of
   * @param _spender address to get number of tokens allowed to be transferred
   *        by the owner of
   * @return number of tokens given spender is currently allowed to transfer
   *         from given owner
   */
  function allowance (address _owner, address _spender)
  constant returns (uint256 remaining) {
    return approved [_owner][_spender];
  }

  /**
   * Create given number of new tokens and give them to given owner.
   *
   * @param _owner address to given new created tokens to the owner of
   * @param _value number of new tokens to create
   */
  function createTokens (address _owner, uint256 _value) internal {
    if (_value > 0) {
      accounts [_owner] = safeAdd (accounts [_owner], _value);
      tokensCount = safeAdd (tokensCount, _value);
    }
  }

  /**
   * Perform token transfer.
   *
   * @param _from address to transfer tokens from the owner of
   * @param _to address to transfer tokens to to the owner of
   * @param _value number of tokens to transfer
   * @return true if tokens were transferred successfully, false otherwise
   */
  function doTransfer (address _from, address _to, uint256 _value)
  private returns (bool success) {
    if (_value > accounts [_from]) return false;
    if (_value > 0 && _from != _to) {
      accounts [_from] = safeSub (accounts [_from], _value);
      accounts [_to] = safeAdd (accounts [_to], _value);
      Transfer (_from, _to, _value);
    }
    return true;
  }

  /**
   * Total number of tokens in circulation.
   */
  uint256 tokensCount;

  /**
   * Maps addresses of token owners to states of their accounts.
   */
  mapping (address => uint256) accounts;

  /**
   * Maps addresses of token owners to mappings from addresses of spenders to
   * how many tokens belonging to the owner, the spender is currently allowed to
   * transfer.
   */
  mapping (address => mapping (address => uint256)) approved;
}

/**
 * Standard Token smart contract that provides the following features:
 * <ol>
 *   <li>Centralized creation of new tokens</li> 
 *   <li>Freeze/unfreeze token transfers</li>
 *   <li>Change owner</li>
 * </ol>
 */
contract StandardToken is AbstractToken {
  /**
   * Maximum allowed tokens in circulation (2^64 - 1).
   */
  uint256 constant private MAX_TOKENS = 0xFFFFFFFFFFFFFFFF;

  /**
   * Address of the owner of the contract.
   */
  address owner;

  /**
   * Whether transfers are currently frozen.
   */
  bool frozen;

  /**
   * Instantiate the contract and make the message sender to be the owner.
   */
  function StandardToken () {
    owner = msg.sender;
  }

  /**
   * Transfer given number of tokens from message sender to given recipient.
   *
   * @param _to address to transfer tokens from the owner of
   * @param _value number of tokens to transfer to the owner of given address
   * @return true if tokens were transferred successfully, false otherwise
   */
  function transfer (address _to, uint256 _value)
  returns (bool success) {
    if (frozen) return false;
    else return AbstractToken.transfer (_to, _value);
  }

  /**
   * Transfer given number of tokens from given owner to given recipient.
   *
   * @param _from address to transfer tokens from the owner of
   * @param _to address to transfer tokens to the owner of
   * @param _value number of tokens to transfer from given owner to given
            recipient
   * @return true if tokens were transferred successfully, false otherwise
   */
  function transferFrom (address _from, address _to, uint256 _value)
  returns (bool success) {
    if (frozen) return false;
    else return AbstractToken.transferFrom (_from, _to, _value);
  }

  /**
   * Create certain number of new tokens and give them to the owner of the
   * contract.
   * 
   * @param _value number of new tokens to create
   * @return true if tokens were created successfully, false otherwise
   */
  function createTokens (uint256 _value)
  returns (bool success) {
    if (msg.sender != owner) throw;

    if (_value > MAX_TOKENS - totalSupply ()) return false;

    AbstractToken.createTokens (owner, _value);

    return true;
  }

  /**
   * Freeze token transfers.
   */
  function freezeTransfers () {
    if (msg.sender != owner) throw;

    if (!frozen)
    {
      frozen = true;
      Freeze ();
    }
  }

  /**
   * Unfreeze token transfers.
   */
  function unfreezeTransfers () {
    if (msg.sender != owner) throw;

    if (frozen) {
      frozen = false;
      Unfreeze ();
    }
  }

  /**
   * Set new owner address.
   *
   * @param _newOwner new owner address
   */
  function setOwner (address _newOwner) {
    if (msg.sender != owner) throw;

    owner = _newOwner;
  }

  /**
   * Logged when token transfers were freezed.
   */
  event Freeze ();

  /**
   * Logged when token transfers were unfreezed.
   */
  event Unfreeze ();
}

/**
 * Giga Watt Token Smart Contract.
 */
contract GigaWattToken is StandardToken {
  /**
   * Constructor just calls constructor of parent contract.
   */
  function GigaWattToken () StandardToken () {
    // Do nothing
  }
}