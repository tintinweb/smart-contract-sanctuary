pragma solidity ^0.4.21;
/*
 * Abstract Token Smart Contract.  Copyright &#169; 2017 by ABDK Consulting.
 * Author: Mikhail Vladimirov <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="0d606466656c6461237b616c696460647f627b4d6a606c6461236e6260">[email&#160;protected]</a>>
 */

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
  function totalSupply () public constant returns (uint256 supply);

  /**
   * Get number of tokens currently belonging to given owner.
   *
   * @param _owner address to get number of tokens currently belonging to the
   *        owner of
   * @return number of tokens currently belonging to the owner of given address
   */
  function balanceOf (address _owner) public constant returns (uint256 balance);

  /**
   * Transfer given number of tokens from message sender to given recipient.
   *
   * @param _to address to transfer tokens to the owner of
   * @param _value number of tokens to transfer to the owner of given address
   * @return true if tokens were transferred successfully, false otherwise
   */
  function transfer (address _to, uint256 _value) public returns (bool success);

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
  public returns (bool success);

  /**
   * Allow given spender to transfer given number of tokens from message sender.
   *
   * @param _spender address to allow the owner of to transfer tokens from
   *        message sender
   * @param _value number of tokens to allow to transfer
   * @return true if token transfer was successfully approved, false otherwise
   */
  function approve (address _spender, uint256 _value) public returns (bool success);

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
  function allowance (address _owner, address _spender) constant
  public returns (uint256 remaining);

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
/*
 * Safe Math Smart Contract.  Copyright &#169; 2016–2017 by ABDK Consulting.
 * Author: Mikhail Vladimirov <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="74191d1f1c151d185a021815101d191d061b02341319151d185a171b19">[email&#160;protected]</a>>
 */

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
  pure internal
  returns (uint256 z) {
    assert (x <= MAX_UINT256 - y);
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
  pure internal
  returns (uint256 z) {
    assert (x >= y);
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
  pure internal
  returns (uint256 z) {
    if (y == 0) return 0; // Prevent division by zero at the next line
    assert (x <= MAX_UINT256 / y);
    return x * y;
  }
}
/**
 * Abstract Token Smart Contract that could be used as a base contract for
 * ERC-20 token contracts.
 */

contract AbstractToken is Token, SafeMath {
  /**
   * Create new Abstract Token contract.
   */
  function AbstractToken () public {
    // Do nothing
  }

  /**
   * Get number of tokens currently belonging to given owner.
   *
   * @param _owner address to get number of tokens currently belonging to the
   *        owner of
   * @return number of tokens currently belonging to the owner of given address
   */
  function balanceOf (address _owner) public constant returns (uint256 balance) {
    return accounts [_owner];
  }

  /**
   * Get number of tokens currently belonging to given owner and available for transfer.
   *
   * @param _owner address to get number of tokens currently belonging to the
   *        owner of
   * @return number of tokens currently belonging to the owner of given address
   */
  function transferrableBalanceOf (address _owner) public constant returns (uint256 balance) {
    if (holds[_owner] > accounts[_owner]) {
        return 0;
    } else {
        return safeSub(accounts[_owner], holds[_owner]);
    }
  }

  /**
   * Transfer given number of tokens from message sender to given recipient.
   *
   * @param _to address to transfer tokens to the owner of
   * @param _value number of tokens to transfer to the owner of given address
   * @return true if tokens were transferred successfully, false otherwise
   */
  function transfer (address _to, uint256 _value) public returns (bool success) {
    require (transferrableBalanceOf(msg.sender) >= _value);
    if (_value > 0 && msg.sender != _to) {
      accounts [msg.sender] = safeSub (accounts [msg.sender], _value);
      if (!hasAccount[_to]) {
          hasAccount[_to] = true;
          accountList.push(_to);
      }
      accounts [_to] = safeAdd (accounts [_to], _value);
    }
    emit Transfer (msg.sender, _to, _value);
    return true;
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
  public returns (bool success) {
    require (allowances [_from][msg.sender] >= _value);
    require (transferrableBalanceOf(_from) >= _value);

    allowances [_from][msg.sender] =
      safeSub (allowances [_from][msg.sender], _value);

    if (_value > 0 && _from != _to) {
      accounts [_from] = safeSub (accounts [_from], _value);
      if (!hasAccount[_to]) {
          hasAccount[_to] = true;
          accountList.push(_to);
      }
      accounts [_to] = safeAdd (accounts [_to], _value);
    }
    emit Transfer (_from, _to, _value);
    return true;
  }

  /**
   * Allow given spender to transfer given number of tokens from message sender.
   *
   * @param _spender address to allow the owner of to transfer tokens from
   *        message sender
   * @param _value number of tokens to allow to transfer
   * @return true if token transfer was successfully approved, false otherwise
   */
  function approve (address _spender, uint256 _value) public returns (bool success) {
    allowances [msg.sender][_spender] = _value;
    emit Approval (msg.sender, _spender, _value);

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
  function allowance (address _owner, address _spender) public constant
  returns (uint256 remaining) {
    return allowances [_owner][_spender];
  }

  /**
   * Mapping from addresses of token holders to the numbers of tokens belonging
   * to these token holders.
   */
  mapping (address => uint256) accounts;

  /**
   * Mapping from address of token holders to a boolean to indicate if they have
   * already been added to the system.
   */
  mapping (address => bool) internal hasAccount;
  
  /**
   * List of available accounts.
   */
  address [] internal accountList;
  
  /**
   * Mapping from addresses of token holders to the mapping of addresses of
   * spenders to the allowances set by these token holders to these spenders.
   */
  mapping (address => mapping (address => uint256)) private allowances;

  /**
   * Mapping from addresses of token holds which cannot be spent until released.
   */
  mapping (address =>  uint256) internal holds;
}
/**
 * Ponder token smart contract.
 */


contract PonderAirdropToken is AbstractToken {
  /**
   * Address of the owner of this smart contract.
   */
  mapping (address => bool) private owners;
  
  /**
   * Address of the account which holds the supply
   */
  address private supplyOwner;
  
  /**
   * True if tokens transfers are currently frozen, false otherwise.
   */
  bool frozen = false;

  /**
   * Create new Ponder token smart contract, with given number of tokens issued
   * and given to msg.sender, and make msg.sender the owner of this smart
   * contract.
   */
  function PonderAirdropToken () public {
    supplyOwner = msg.sender;
    owners[supplyOwner] = true;
    accounts [supplyOwner] = totalSupply();
    hasAccount [supplyOwner] = true;
    accountList.push(supplyOwner);
  }

  /**
   * Get total number of tokens in circulation.
   *
   * @return total number of tokens in circulation
   */
  function totalSupply () public constant returns (uint256 supply) {
    return 480000000 * (uint256(10) ** decimals());
  }

  /**
   * Get name of this token.
   *
   * @return name of this token
   */
  function name () public pure returns (string result) {
    return "Ponder Airdrop Token";
  }

  /**
   * Get symbol of this token.
   *
   * @return symbol of this token
   */
  function symbol () public pure returns (string result) {
    return "PONA";
  }

  /**
   * Get number of decimals for this token.
   *
   * @return number of decimals for this token
   */
  function decimals () public pure returns (uint8 result) {
    return 18;
  }

  /**
   * Transfer given number of tokens from message sender to given recipient.
   *
   * @param _to address to transfer tokens to the owner of
   * @param _value number of tokens to transfer to the owner of given address
   * @return true if tokens were transferred successfully, false otherwise
   */
  function transfer (address _to, uint256 _value) public returns (bool success) {
    if (frozen) return false;
    else return AbstractToken.transfer (_to, _value);
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
    public returns (bool success) {
    if (frozen) return false;
    else return AbstractToken.transferFrom (_from, _to, _value);
  }

  /**
   * Change how many tokens given spender is allowed to transfer from message
   * spender.  In order to prevent double spending of allowance, this method
   * receives assumed current allowance value as an argument.  If actual
   * allowance differs from an assumed one, this method just returns false.
   *
   * @param _spender address to allow the owner of to transfer tokens from
   *        message sender
   * @param _currentValue assumed number of tokens currently allowed to be
   *        transferred
   * @param _newValue number of tokens to allow to transfer
   * @return true if token transfer was successfully approved, false otherwise
   */
  function approve (address _spender, uint256 _currentValue, uint256 _newValue)
    public returns (bool success) {
    if (allowance (msg.sender, _spender) == _currentValue)
      return approve (_spender, _newValue);
    else return false;
  }

  /**
   * Set new owner for the smart contract.
   * May only be called by smart contract owner.
   *
   * @param _address of new or existing owner of the smart contract
   * @param _value boolean stating if the _address should be an owner or not
   */
  function setOwner (address _address, bool _value) public {
    require (owners[msg.sender]);
    // if removing the _address from owners list, make sure owner is not 
    // removing himself (which could lead to an ownerless contract).
    require (_value == true || _address != msg.sender);

    owners[_address] = _value;
  }

  /**
   * Initialize the token holders by contract owner
   *
   * @param _to addresses to allocate token for
   * @param _value number of tokens to be allocated
   */  
  function initAccounts (address [] _to, uint256 [] _value) public {
      require (owners[msg.sender]);
      require (_to.length == _value.length);
      for (uint256 i=0; i < _to.length; i++){
          uint256 amountToAdd;
          uint256 amountToSub;
          if (_value[i] > accounts[_to[i]]){
            amountToAdd = safeSub(_value[i], accounts[_to[i]]);
          }else{
            amountToSub = safeSub(accounts[_to[i]], _value[i]);
          }
          accounts [supplyOwner] = safeAdd (accounts [supplyOwner], amountToSub);
          accounts [supplyOwner] = safeSub (accounts [supplyOwner], amountToAdd);
          if (!hasAccount[_to[i]]) {
              hasAccount[_to[i]] = true;
              accountList.push(_to[i]);
          }
          accounts [_to[i]] = _value[i];
          if (amountToAdd > 0){
            emit Transfer (supplyOwner, _to[i], amountToAdd);
          }
      }
  }

  /**
   * Initialize the token holders and hold amounts by contract owner
   *
   * @param _to addresses to allocate token for
   * @param _value number of tokens to be allocated
   * @param _holds number of tokens to hold from transferring
   */  
  function initAccounts (address [] _to, uint256 [] _value, uint256 [] _holds) public {
    setHolds(_to, _holds);
    initAccounts(_to, _value);
  }
  
  /**
   * Set the number of tokens to hold from transferring for a list of 
   * token holders.
   * 
   * @param _account list of account holders
   * @param _value list of token amounts to hold
   */
  function setHolds (address [] _account, uint256 [] _value) public {
    require (owners[msg.sender]);
    require (_account.length == _value.length);
    for (uint256 i=0; i < _account.length; i++){
        holds[_account[i]] = _value[i];
    }
  }
  
  /**
   * Get the number of account holders (for owner use)
   *
   * @return uint256
   */  
  function getNumAccounts () public constant returns (uint256 count) {
    require (owners[msg.sender]);
    return accountList.length;
  }
  
  /**
   * Get a list of account holder eth addresses (for owner use)
   *
   * @param _start index of the account holder list
   * @param _count of items to return
   * @return array of addresses
   */  
  function getAccounts (uint256 _start, uint256 _count) public constant returns (address [] addresses){
    require (owners[msg.sender]);
    require (_start >= 0 && _count >= 1);
    if (_start == 0 && _count >= accountList.length) {
      return accountList;
    }
    address [] memory _slice = new address[](_count);
    for (uint256 i=0; i < _count; i++){
      _slice[i] = accountList[i + _start];
    }
    return _slice;
  }
  
  /**
   * Freeze token transfers.
   * May only be called by smart contract owner.
   */
  function freezeTransfers () public {
    require (owners[msg.sender]);

    if (!frozen) {
      frozen = true;
      emit Freeze ();
    }
  }

  /**
   * Unfreeze token transfers.
   * May only be called by smart contract owner.
   */
  function unfreezeTransfers () public {
    require (owners[msg.sender]);

    if (frozen) {
      frozen = false;
      emit Unfreeze ();
    }
  }

  /**
   * Logged when token transfers were frozen.
   */
  event Freeze ();

  /**
   * Logged when token transfers were unfrozen.
   */
  event Unfreeze ();

  /**
   * Kill the token.
   */
  function kill() public { 
    if (owners[msg.sender]) selfdestruct(msg.sender);
  }
}