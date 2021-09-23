// SPDX-License-Identifier: UNLICENSED
/*
 * CyberCash (CC) Token Smart Contract.
 * Copyright (c) 2018 by CyberCash
 * Contact: <[email protected]>
 */
pragma solidity ^0.8.0;

import "./AbstractToken.sol";

/**
 * CC Token Smart Contract: EIP-20 compatible token smart contract that
 * manages CC tokens.
 */
contract CCToken is AbstractToken {
  /**
   * @dev Fee denominator (0.001%).
   */
  uint256 constant internal FEE_DENOMINATOR = 100000;

  /**
   * @dev Maximum fee numerator (100%).
   */
  uint256 constant internal MAX_FEE_NUMERATOR = FEE_DENOMINATOR;

  /**
   * @dev Maximum allowed number of tokens in circulation.
   */
  uint256 constant internal MAX_TOKENS_COUNT =
    244000000000000000000 /
    MAX_FEE_NUMERATOR;

  /**
   * @dev Address flag that marks black listed addresses.
   */
  uint256 constant internal BLACK_LIST_FLAG = 0x01;

  /**
   * Create CC Token smart contract with message sender as an owner.
   */
  constructor () {
    owner = msg.sender;
  }

  /**
   * Get name of the token.
   *
   * @return name of the token
   */
  function name () public pure returns (string memory) {
    return "CYBERCASH";
  }

  /**
   * Get symbol of the token.
   *
   * @return symbol of the token
   */
  function symbol () public pure returns (string memory) {
    return "CC";
  }

  /**
   * Get number of decimals for the token.
   *
   * @return number of decimals for the token
   */
  function decimals () public pure returns (uint8) {
    return 5;
  }

  /**
   * Get total number of tokens in circulation.
   *
   * @return total number of tokens in circulation
   */
  function totalSupply () public override view returns (uint256) {
    return tokensCount;
  }

  /**
   * Get number of tokens currently belonging to given owner.
   *
   * @param _owner address to get number of tokens currently belonging to the
   *        owner of
   * @return balance number of tokens currently belonging to the owner of given address
   */
  function balanceOf (address _owner)
    public override view returns (uint256 balance) {
    return AbstractToken.balanceOf (_owner);
  }

  /**
   * Transfer given number of tokens from message sender to given recipient.
   *
   * @param _to address to transfer tokens to the owner of
   * @param _value number of tokens to transfer to the owner of given address
   * @return true if tokens were transferred successfully, false otherwise
   */
  function transfer (address _to, uint256 _value)
  public override virtual returns (bool) {
    if (frozen) return false;
    else if (
      (addressFlags [msg.sender] | addressFlags [_to]) & BLACK_LIST_FLAG ==
      BLACK_LIST_FLAG)
      return false;
    else {
      if (_value <= accounts [msg.sender]) {
        require (AbstractToken.transfer (_to, _value));
        return true;
      } else return false;
    }
  }

  /**
   * Transfer given number of tokens from given owner to given recipient.
   *
   * @param _from address to transfer tokens from the owner of
   * @param _to address to transfer tokens to the owner of
   * @param _value number of tokens to transfer from given owner to given
   *        recipient
   * @return true if tokens were transferred successfully, false otherwise
   */
  function transferFrom (address _from, address _to, uint256 _value)
  public override virtual returns (bool) {
    if (frozen) return false;
    else if (
      (addressFlags [_from] | addressFlags [_to]) & BLACK_LIST_FLAG ==
      BLACK_LIST_FLAG)
      return false;
    else {
      if (_value <= allowances [_from][msg.sender] &&
          _value <= accounts [_from]) {
        require (AbstractToken.transferFrom (_from, _to, _value));
        return true;
      } else return false;
    }
  }

  /**
   * Allow given spender to transfer given number of tokens from message sender.
   *
   * @param _spender address to allow the owner of to transfer tokens from
   *        message sender
   * @param _value number of tokens to allow to transfer
   * @return success true if token transfer was successfully approved, false otherwise
   */
  function approve (address _spender, uint256 _value)
  public override returns (bool success) {
    return AbstractToken.approve (_spender, _value);
  }

  /**
   * Tell how many tokens given spender is currently allowed to transfer from
   * given owner.
   *
   * @param _owner address to get number of tokens allowed to be transferred
   *        from the owner of
   * @param _spender address to get number of tokens allowed to be transferred
   *        by the owner of
   * @return remaining number of tokens given spender is currently allowed to transfer
   *         from given owner
   */
  function allowance (address _owner, address _spender)
  public override view returns (uint256 remaining) {
    return AbstractToken.allowance (_owner, _spender);
  }

  /**
   * Transfer given number of token from the signed defined by digital signature
   * to given recipient.
   *
   * @param _to address to transfer token to the owner of
   * @param _value number of tokens to transfer
   * @param _fee number of tokens to give to message sender
   * @param _nonce nonce of the transfer
   * @param _v parameter V of digital signature
   * @param _r parameter R of digital signature
   * @param _s parameter S of digital signature
   */
  function delegatedTransfer (
    address _to, uint256 _value, uint256 _fee,
    uint256 _nonce, uint8 _v, bytes32 _r, bytes32 _s)
  public virtual returns (bool) {
    if (frozen) return false;
    else {
      address _from = ecrecover (
        keccak256 (
          abi.encodePacked (
            thisAddress (), messageSenderAddress (), _to, _value, _fee, _nonce)),
        _v, _r, _s);

      if (_from == address (0)) return false;

      if (_nonce != nonces [_from]) return false;

      if (
        (addressFlags [_from] | addressFlags [_to]) & BLACK_LIST_FLAG ==
        BLACK_LIST_FLAG)
        return false;

      uint256 balance = accounts [_from];
      if (_value > balance) return false;
      balance = balance - _value;
      if (_fee > balance) return false;
      balance = balance - _fee;

      nonces [_from] = _nonce + 1;

      accounts [_from] = balance;
      accounts [_to] = accounts [_to] + _value;
      accounts [msg.sender] = accounts [msg.sender] + _fee;

      emit Transfer (_from, _to, _value);
      emit Transfer (_from, msg.sender, _fee);

      return true;
    }
  }

  /**
   * Create tokens.
   *
   * @param _value number of tokens to be created.
   */
  function createTokens (uint256 _value)
  public virtual returns (bool) {
    require (msg.sender == owner);

    if (_value > 0) {
      if (_value <= MAX_TOKENS_COUNT - tokensCount) {
        accounts [msg.sender] = accounts [msg.sender] + _value;
        tokensCount = tokensCount + _value;

        emit Transfer (address (0), msg.sender, _value);

        return true;
      } else return false;
    } else return true;
  }

  /**
   * Burn tokens.
   *
   * @param _value number of tokens to burn
   */
  function burnTokens (uint256 _value)
  public virtual returns (bool) {
    require (msg.sender == owner);

    if (_value > 0) {
      if (_value <= accounts [msg.sender]) {
        accounts [msg.sender] = accounts [msg.sender] - _value;
        tokensCount = tokensCount - _value;

        emit Transfer (msg.sender, address (0), _value);

        return true;
      } else return false;
    } else return true;
  }

  /**
   * Freeze token transfers.
   */
  function freezeTransfers () public {
    require (msg.sender == owner);

    if (!frozen) {
      frozen = true;

      emit Freeze ();
    }
  }

  /**
   * Unfreeze token transfers.
   */
  function unfreezeTransfers () public {
    require (msg.sender == owner);

    if (frozen) {
      frozen = false;

     emit Unfreeze ();
    }
  }

  /**
   * Set smart contract owner.
   *
   * @param _newOwner address of the new owner
   */
  function setOwner (address _newOwner) public {
    require (msg.sender == owner);

    owner = _newOwner;
  }

  /**
   * Get current nonce for token holder with given address, i.e. nonce this
   * token holder should use for next delegated transfer.
   *
   * @param _owner address of the token holder to get nonce for
   * @return current nonce for token holder with give address
   */
  function nonce (address _owner) public view returns (uint256) {
    return nonces [_owner];
  }

  /**
   * Get fee parameters.
   *
   * @return _fixedFee fixed fee
   * @return _minVariableFee minimum variable fee
   * @return _maxVariableFee maximum variable fee
   * @return _variableFeeNumnerator variable fee numerator
   */
  function getFeeParameters () public pure returns (
    uint256 _fixedFee,
    uint256 _minVariableFee,
    uint256 _maxVariableFee,
    uint256 _variableFeeNumnerator) {
    _fixedFee = 0;
    _minVariableFee = 0;
    _maxVariableFee = 0;
    _variableFeeNumnerator = 0;
  }

  /**
   * Calculate fee for transfer of given number of tokens.
   *
   * @param _amount transfer amount to calculate fee for
   * @return _fee fee for transfer of given amount
   */
  function calculateFee (uint256 _amount)
    public pure returns (uint256 _fee) {
    require (_amount <= MAX_TOKENS_COUNT);

    _fee = 0;
  }

  /**
   * Set flags for given address.
   *
   * @param _address address to set flags for
   * @param _flags flags to set
   */
  function setFlags (address _address, uint256 _flags)
  public {
    require (msg.sender == owner);

    addressFlags [_address] = _flags;
  }

  /**
   * Get flags for given address.
   *
   * @param _address address to get flags for
   * @return flags for given address
   */
  function flags (address _address) public view returns (uint256) {
    return addressFlags [_address];
  }

  /**
   * Get address of this smart contract.
   *
   * @return address of this smart contract
   */
  function thisAddress () internal virtual view returns (address) {
    return address(this);
  }

  /**
   * Get address of message sender.
   *
   * @return address of this smart contract
   */
  function messageSenderAddress () internal virtual view returns (address) {
    return msg.sender;
  }

  /**
   * @dev Owner of the smart contract.
   */
  address internal owner;

  /**
   * @dev Address where fees are sent to.  Not used anymore.
   */
  address internal feeCollector;

  /**
   * @dev Number of tokens in circulation.
   */
  uint256 internal tokensCount;

  /**
   * @dev Whether token transfers are currently frozen.
   */
  bool internal frozen;

  /**
   * @dev Mapping from sender's address to the next delegated transfer nonce.
   */
  mapping (address => uint256) internal nonces;

  /**
   * @dev Fixed fee amount in token units.  Not used anymore.
   */
  uint256 internal fixedFee;

  /**
   * @dev Minimum variable fee in token units.  Not used anymore.
   */
  uint256 internal minVariableFee;

  /**
   * @dev Maximum variable fee in token units.  Not used anymore.
   */
  uint256 internal maxVariableFee;

  /**
   * @dev Variable fee numerator.  Not used anymore.
   */
  uint256 internal variableFeeNumerator;

  /**
   * @dev Maps address to its flags.
   */
  mapping (address => uint256) internal addressFlags;

  /**
   * @dev Address of smart contract to delegate execution of delegatable methods to,
   * or zero to not delegate delegatable methods execution.  Not used in upgrade.
   */
  address internal delegate;

  /**
   * Logged when token transfers were frozen.
   */
  event Freeze ();

  /**
   * Logged when token transfers were unfrozen.
   */
  event Unfreeze ();
}